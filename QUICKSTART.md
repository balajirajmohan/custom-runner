# 🚀 Quick Start Guide

Get your GitHub self-hosted runner with Docker up and running in 15 minutes!

## ⚡ Prerequisites Check

Before starting, ensure you have:

- [ ] AWS account with credentials configured (`aws configure`)
- [ ] GitHub account and repository
- [ ] Terraform installed (`terraform --version`)
- [ ] SSH key pair (or will create one)
- [ ] GitHub Personal Access Token (PAT)

## 📝 Step-by-Step Setup

### 1️⃣ Generate GitHub Token (2 minutes)

1. Go to: https://github.com/settings/tokens
2. Click "Generate new token" → "Generate new token (classic)"
3. Name: `github-runner-token`
4. Select scopes: ✅ **repo** (all)
5. Click "Generate token"
6. **Copy the token** (you won't see it again!)

### 2️⃣ Create SSH Key (1 minute)

```bash
# Generate SSH key if you don't have one
ssh-keygen -t rsa -b 4096 -f ~/.ssh/github-runner -N ""

# View your public key (you'll need this)
cat ~/.ssh/github-runner.pub
```

### 3️⃣ Get Your Public IP (30 seconds)

```bash
curl ifconfig.me
# Note this down - e.g., 203.0.113.45
```

### 4️⃣ Find Your AMI ID (Optional - 2 minutes)

If NOT using `us-east-1`:

1. Go to: https://cloud-images.ubuntu.com/locator/ec2/
2. Search: `22.04 LTS` + your region
3. Copy the AMI ID for `amd64` architecture

### 5️⃣ Configure Terraform (3 minutes)

```bash
cd terraform

# Copy example file
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
nano terraform.tfvars  # or vim, code, etc.
```

**Fill in these values:**

```hcl
aws_region     = "us-east-1"  # Your AWS region
project_name   = "github-runner"

# Paste your SSH public key from step 2
ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAA..."

# Paste your GitHub token from step 1
github_token = "ghp_xxxxxxxxxxxxxxxxxxxx"

# Your GitHub repo URL (HTTPS format)
github_repo_url = "https://github.com/YOUR_USERNAME/YOUR_REPO"

# Name for your runner
runner_name = "aws-docker-runner-01"

# Your IP from step 3
ssh_allowed_ips = ["203.0.113.45/32"]

# AMI ID (only if NOT us-east-1)
ami_id = "ami-0c7217cdde317cfec"
```

### 6️⃣ Deploy Infrastructure (5 minutes)

```bash
# Initialize Terraform
terraform init

# Preview changes
terraform plan

# Deploy (type 'yes' when prompted)
terraform apply
```

☕ **Wait 5-7 minutes** for the instance to be created and configured.

### 7️⃣ Verify Setup (2 minutes)

```bash
# Get the runner's public IP
terraform output runner_public_ip

# SSH into the instance (replace IP)
ssh -i ~/.ssh/github-runner ubuntu@<RUNNER_PUBLIC_IP>

# Check runner status
sudo systemctl status actions.runner.*

# Check Docker
docker --version

# Run verification script
/home/runner/verify-setup.sh

# Exit SSH
exit
```

### 8️⃣ Verify in GitHub (1 minute)

1. Go to your GitHub repository
2. Click: **Settings** → **Actions** → **Runners**
3. You should see your runner listed as "Idle" with a green dot 🟢

### 9️⃣ Push Code and Test (2 minutes)

```bash
# Go back to project root
cd /Users/balajibr/Desktop/customrunner

# Initialize git (if not done)
git init

# Add all files
git add .

# Commit
git commit -m "Initial setup: Self-hosted runner with Docker"

# Add your GitHub repo as remote
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git

# Push to GitHub
git branch -M main
git push -u origin main
```

### 🎉 Watch It Run!

1. Go to your GitHub repository
2. Click the **Actions** tab
3. You should see workflows running:
   - "Simple Test Workflow" 
   - "CI with Self-Hosted Runner (Docker)"

---

## ✅ Success Checklist

Your setup is working if:

- [ ] Runner appears in GitHub Settings → Actions → Runners
- [ ] Runner status is "Idle" (green dot)
- [ ] Workflows appear in Actions tab
- [ ] Workflow jobs complete successfully
- [ ] You can SSH into the runner
- [ ] Docker commands work on the runner

---

## 🐛 Quick Troubleshooting

### Runner not appearing in GitHub?

```bash
ssh -i ~/.ssh/github-runner ubuntu@<RUNNER_IP>
sudo journalctl -u actions.runner.* -n 50
```

### Can't SSH?

- Check security group allows your IP
- Verify SSH key path: `chmod 600 ~/.ssh/github-runner`
- Confirm you're using the right IP

### Workflow not running?

- Check workflow file syntax
- Ensure `runs-on: self-hosted` is set
- Verify runner is "Idle" not "Offline"

### Need logs?

```bash
# User data execution log
sudo cat /var/log/user-data.log

# Runner service logs
sudo journalctl -u actions.runner.* -f

# Docker logs
docker logs <container-id>
```

---

## 🧹 Cleanup When Done

**Important**: Don't forget to destroy resources to avoid AWS charges!

```bash
cd terraform
terraform destroy
# Type 'yes' when prompted
```

This will:
- ✅ Terminate the EC2 instance
- ✅ Delete VPC and networking
- ✅ Remove the runner from GitHub
- ✅ Stop all AWS charges

---

## 📚 Next Steps

Now that it's working:

1. ✅ Read [CONCEPTS.md](./CONCEPTS.md) to understand how it works
2. ✅ Customize the workflows in `.github/workflows/`
3. ✅ Add your own application code
4. ✅ Configure secrets in GitHub (Settings → Secrets and variables → Actions)
5. ✅ Add more tests to your Node.js app
6. ✅ Explore Docker images for different languages

---

## 💡 Tips

**Cost Savings:**
```bash
# Stop instance when not using (instead of destroy)
aws ec2 stop-instances --instance-ids $(terraform output -raw runner_instance_id)

# Start it again when needed
aws ec2 start-instances --instance-ids $(terraform output -raw runner_instance_id)
```

**Security Best Practices:**
- ✅ Always restrict SSH to your IP
- ✅ Rotate GitHub tokens regularly
- ✅ Use IAM roles for AWS permissions
- ✅ Keep runner software updated
- ✅ Monitor runner logs

**Performance Tips:**
- ✅ Use larger instance types for faster builds
- ✅ Cache Docker images on runner
- ✅ Use `npm ci` instead of `npm install`
- ✅ Parallelize jobs when possible

---

## 📞 Need Help?

- 📖 Check [README.md](./README.md) for detailed documentation
- 🎓 Read [CONCEPTS.md](./CONCEPTS.md) for architecture explanation
- 🔍 Search GitHub Actions documentation
- 💬 Open an issue in this repository

---

**Happy Building! 🚀**

