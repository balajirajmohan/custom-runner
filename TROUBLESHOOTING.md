# 🔧 Troubleshooting Guide

Common issues and how to fix them at yuour ease

## 🔍 Quick Diagnostics

### Check Everything At Once

```bash
# SSH into runner
ssh -i ~/.ssh/github-runner ubuntu@<RUNNER_IP>

# Run this comprehensive check
cat << 'EOF' | bash
echo "=== SYSTEM INFO ==="
uname -a
uptime

echo -e "\n=== RUNNER SERVICE STATUS ==="
sudo systemctl status actions.runner.* --no-pager | head -20

echo -e "\n=== DOCKER STATUS ==="
docker --version
systemctl status docker --no-pager | head -10

echo -e "\n=== DISK SPACE ==="
df -h | grep -E "Filesystem|/$"

echo -e "\n=== RECENT RUNNER LOGS ==="
sudo journalctl -u actions.runner.* -n 10 --no-pager

echo -e "\n=== USER DATA LOG (last 20 lines) ==="
sudo tail -20 /var/log/user-data.log

echo -e "\n=== DOCKER IMAGES ==="
docker images

echo -e "\n=== RUNNING CONTAINERS ==="
docker ps

echo -e "\n=== NETWORK CONNECTIVITY ==="
ping -c 3 github.com
EOF
```

---

## 🚨 Common Issues

### 1. Runner Not Appearing in GitHub

**Symptoms:**

- Runner doesn't show up in GitHub Settings → Actions → Runners
- Or shows as "Offline"

**Diagnosis:**

```bash
# Check if runner service is running
sudo systemctl status actions.runner.*

# Check runner logs
sudo journalctl -u actions.runner.* -n 50

# Check user data script completion
sudo tail -100 /var/log/user-data.log
```

**Common Causes & Fixes:**

#### A. Service Not Started

```bash
# Start the service
sudo systemctl start actions.runner.*

# Enable for auto-start
sudo systemctl enable actions.runner.*
```

#### B. Registration Token Expired

Registration tokens expire after 1 hour.

```bash
# Get new token from GitHub API
REPO_URL="https://github.com/USERNAME/REPO"
GITHUB_TOKEN="your_pat_token"
REPO_PATH=$(echo $REPO_URL | sed 's/https:\/\/github.com\///')

NEW_TOKEN=$(curl -s -X POST \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  "https://api.github.com/repos/$REPO_PATH/actions/runners/registration-token" | jq -r .token)

# Reconfigure runner
cd /home/runner/actions-runner
sudo systemctl stop actions.runner.*
sudo -u runner ./config.sh remove
sudo -u runner ./config.sh --url $REPO_URL --token $NEW_TOKEN --name aws-runner --labels docker,aws,self-hosted --unattended
sudo ./svc.sh install runner
sudo ./svc.sh start
```

#### C. Network/Firewall Issues

```bash
# Test GitHub connectivity
curl -v https://api.github.com

# Check if runner can reach GitHub
sudo -u runner bash -c 'cd /home/runner/actions-runner && ./run.sh' &
# Watch for connection errors, then kill with Ctrl+C
```

#### D. Wrong Repository URL

```bash
# Check configured URL
cat /home/runner/actions-runner/.runner | jq .

# If wrong, reconfigure (see section B above)
```

---

### 2. Can't SSH Into Runner

**Symptoms:**

- `ssh: connect to host X.X.X.X port 22: Connection refused`
- `ssh: connect to host X.X.X.X port 22: Connection timed out`

**Diagnosis:**

```bash
# From your local machine
terraform output runner_public_ip

# Check if instance is running
aws ec2 describe-instances --instance-ids $(terraform output -raw runner_instance_id)
```

**Fixes:**

#### A. Wrong IP Address

```bash
# Get correct IP
terraform output runner_public_ip
```

#### B. Security Group Not Allowing Your IP

Your IP might have changed.

```bash
# Get your current IP
curl ifconfig.me

# Update terraform.tfvars with new IP
nano terraform.tfvars
# Update: ssh_allowed_ips = ["YOUR_NEW_IP/32"]

# Apply changes
terraform apply
```

#### C. SSH Key Permissions

```bash
# Fix key permissions
chmod 600 ~/.ssh/github-runner

# Verify
ls -la ~/.ssh/github-runner
```

#### D. Wrong SSH Key

```bash
# Verify which key is configured in Terraform
terraform show | grep key_name

# Use correct key
ssh -i ~/.ssh/github-runner ubuntu@<IP>
```

---

### 3. Workflow Not Running

**Symptoms:**

- Workflow is queued but never starts
- Workflow immediately fails
- Says "No runners available"

**Diagnosis:**

Check GitHub Actions tab for error messages.

**Fixes:**

#### A. Runner Offline

Check if runner is online in GitHub Settings → Actions → Runners.

If offline, see [issue #1](#1-runner-not-appearing-in-github).

#### B. Wrong Runner Label

Your workflow might be requesting wrong labels.

**Workflow file:**

```yaml
runs-on: self-hosted  # ✅ Correct
# OR
runs-on: [self-hosted, docker, aws]  # ✅ Also correct

# ❌ Wrong:
runs-on: ubuntu-latest  # This uses GitHub-hosted runners
```

#### C. Runner Busy

Only one job can run at a time on a single runner.

```bash
# Check if runner is busy
ssh -i ~/.ssh/github-runner ubuntu@<IP>
docker ps  # Will show running container if job is active
```

**Solution:** Wait for current job to finish, or add more runners.

#### D. Workflow Syntax Error

```bash
# Validate workflow locally
# Install act: https://github.com/nektos/act
act --list
```

---

### 4. Docker Permission Denied

**Symptoms:**

```
Got permission denied while trying to connect to the Docker daemon socket
```

**Fix:**

```bash
# Add runner user to docker group
sudo usermod -aG docker runner

# Restart runner service
sudo systemctl restart actions.runner.*

# Verify
sudo -u runner docker ps
```

---

### 5. Container Image Pull Failures

**Symptoms:**

```
Error: image node:18-alpine not found
Unable to pull image
```

**Diagnosis:**

```bash
# Try pulling manually
docker pull node:18-alpine

# Check Docker Hub connectivity
curl -v https://hub.docker.com
```

**Fixes:**

#### A. Network Issues

```bash
# Check internet connectivity
ping -c 3 8.8.8.8
ping -c 3 docker.io

# Check DNS
nslookup hub.docker.com
```

#### B. Disk Space Full

```bash
# Check disk space
df -h

# Clean up Docker
docker system prune -a
```

#### C. Rate Limiting (Docker Hub)

Docker Hub has rate limits for unauthenticated pulls.

**Solution:** Login to Docker Hub

```bash
# On runner
docker login

# Or use GitHub Container Registry in workflow
container:
  image: ghcr.io/owner/image:tag
```

---

### 6. Tests Failing in Container But Pass Locally

**Symptoms:**

- Tests pass on your machine
- Fail in GitHub Actions container

**Common Causes:**

#### A. Missing Environment Variables

```yaml
container:
  image: node:18-alpine
  env:
    NODE_ENV: test
    API_URL: http://localhost:3000
```

#### B. Different Node.js Version

```yaml
# Specify exact version
container:
  image: node:18.17.0-alpine
```

#### C. Missing Dependencies

Some packages need native compilation tools.

```yaml
# Use full image instead of alpine
container:
  image: node:18 # Has build tools

# Or install in alpine
steps:
  - name: Install dependencies
    run: apk add --no-cache python3 make g++
  - name: Install npm packages
    run: npm ci
```

#### D. File Path Issues

Containers use Linux paths, even if you're on Mac/Windows.

```bash
# Always use forward slashes
./scripts/test.sh  # ✅
.\scripts\test.sh  # ❌
```

---

### 7. Slow Workflow Execution

**Symptoms:**

- Workflows take too long
- Container startup is slow

**Optimizations:**

#### A. Cache Docker Images

Images are cached after first pull.

```bash
# Pre-pull common images
docker pull node:18-alpine
docker pull node:20-alpine
docker pull ubuntu:22.04
```

#### B. Use Smaller Images

```yaml
# Alpine images are much smaller
image: node:18-alpine     # ~170 MB
# vs
image: node:18            # ~1 GB
```

#### C. Optimize Dependencies

```yaml
steps:
  # Use ci instead of install (faster)
  - run: npm ci

  # Cache node_modules (if supported)
  - uses: actions/cache@v3
    with:
      path: node_modules
      key: ${{ runner.os }}-node-${{ hashFiles('**/package-lock.json') }}
```

#### D. Increase Instance Size

```hcl
# In terraform.tfvars
instance_type = "t3.large"  # 2 vCPU, 8 GB RAM
```

---

### 8. Out of Disk Space

**Symptoms:**

```
no space left on device
```

**Diagnosis:**

```bash
df -h
docker system df
```

**Fixes:**

#### A. Clean Docker

```bash
# Remove unused containers, images, volumes
docker system prune -a

# Remove specific images
docker images
docker rmi <image-id>
```

#### B. Clean Runner Workspace

```bash
cd /home/runner/actions-runner/_work
du -sh *
rm -rf old-repo-dirs
```

#### C. Increase EBS Volume

```hcl
# In terraform/main.tf
root_block_device {
  volume_size = 50  # Increase from 30 GB
  volume_type = "gp3"
}

# Apply
terraform apply
```

Then resize filesystem:

```bash
# SSH into instance
sudo growpart /dev/xvda 1
sudo resize2fs /dev/xvda1
```

---

### 9. Runner Stuck in "Busy" State

**Symptoms:**

- Job completed but runner still shows "Busy"
- New jobs won't start

**Fix:**

```bash
# Restart runner service
sudo systemctl restart actions.runner.*

# If that doesn't work, force cleanup
sudo systemctl stop actions.runner.*
cd /home/runner/actions-runner/_work
sudo rm -rf *
sudo systemctl start actions.runner.*
```

---

### 10. Terraform Apply Fails

**Common Errors:**

#### A. "InvalidKeyPair.NotFound"

```bash
# Your SSH public key might be invalid
# Regenerate:
ssh-keygen -t rsa -b 4096 -f ~/.ssh/github-runner -N ""

# Copy public key content to terraform.tfvars
cat ~/.ssh/github-runner.pub
```

#### B. "InvalidAMIID.NotFound"

```bash
# AMI ID is region-specific
# Find correct AMI for your region:
# Visit: https://cloud-images.ubuntu.com/locator/ec2/
# Search: 22.04 LTS + your region
```

#### C. "VPC limit exceeded"

```bash
# You have too many VPCs
# Delete old ones:
aws ec2 describe-vpcs
aws ec2 delete-vpc --vpc-id vpc-xxxxx
```

---

## 🔬 Advanced Debugging

### Enable Runner Debug Logging

In GitHub repo:

1. Settings → Secrets and variables → Actions
2. Add secret: `ACTIONS_RUNNER_DEBUG` = `true`
3. Add secret: `ACTIONS_STEP_DEBUG` = `true`

Next workflow run will have verbose logs.

### Monitor Runner in Real-Time

```bash
# Terminal 1: Watch runner logs
sudo journalctl -u actions.runner.* -f

# Terminal 2: Watch Docker
watch -n 2 docker ps

# Terminal 3: Watch system resources
htop
```

### Check Runner Configuration

```bash
cat /home/runner/actions-runner/.runner | jq .
cat /home/runner/actions-runner/.credentials | jq .
```

### Manual Runner Test

```bash
# Stop service
sudo systemctl stop actions.runner.*

# Run manually (foreground)
cd /home/runner/actions-runner
sudo -u runner ./run.sh

# Watch output, Ctrl+C to stop
# Then restart service
sudo systemctl start actions.runner.*
```

---

## 📞 Getting Help

### Collect Diagnostic Information

Before asking for help, collect this info:

```bash
# Create diagnostic bundle
ssh -i ~/.ssh/github-runner ubuntu@<IP> << 'EOF' > diagnostics.txt
echo "=== Terraform Version ==="
terraform version

echo -e "\n=== AWS CLI Version ==="
aws --version

echo -e "\n=== Instance Info ==="
curl -s http://169.254.169.254/latest/meta-data/instance-id
curl -s http://169.254.169.254/latest/meta-data/instance-type

echo -e "\n=== Runner Status ==="
sudo systemctl status actions.runner.* --no-pager

echo -e "\n=== Docker Info ==="
docker version
docker info

echo -e "\n=== Disk Usage ==="
df -h

echo -e "\n=== Recent Logs ==="
sudo journalctl -u actions.runner.* -n 50 --no-pager

echo -e "\n=== Runner Config ==="
cat /home/runner/actions-runner/.runner | jq .

echo -e "\n=== Network Test ==="
curl -v https://api.github.com 2>&1 | head -20
EOF

cat diagnostics.txt
```

### Useful Links

- **GitHub Actions Docs**: https://docs.github.com/en/actions
- **Runner Releases**: https://github.com/actions/runner/releases
- **Terraform AWS Docs**: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
- **Docker Docs**: https://docs.docker.com/

### Community Help

- **GitHub Community**: https://github.community/
- **Stack Overflow**: Tag with `github-actions`, `self-hosted-runner`

---

## 🛟 Emergency Procedures

### Complete Reset

If nothing works, start fresh:

```bash
# 1. Destroy everything
cd terraform
terraform destroy

# 2. Clean local state
rm -rf .terraform terraform.tfstate*

# 3. Start over
terraform init
terraform apply
```

### Remove Runner from GitHub Manually

If runner is stuck in GitHub:

1. Go to: Settings → Actions → Runners
2. Click on runner name
3. Click "Remove runner"
4. Confirm

### Force Deregister Runner

```bash
# SSH into runner
cd /home/runner/actions-runner
sudo systemctl stop actions.runner.*
sudo -u runner ./config.sh remove --token <NEW_TOKEN>
```

---

## ✅ Prevention Checklist

Avoid issues in the first place:

- [ ] Always use `.tfvars` for sensitive data
- [ ] Keep Terraform state backed up
- [ ] Document your IP address for SSH access
- [ ] Set up CloudWatch alarms for disk space
- [ ] Regularly update runner software
- [ ] Monitor GitHub Actions usage
- [ ] Test workflows in a separate branch first
- [ ] Keep Docker images small
- [ ] Clean up old containers/images weekly
- [ ] Use `npm ci` instead of `npm install`
- [ ] Pin Docker image versions in production

---

**Still stuck?** Open an issue with your diagnostic bundle!
