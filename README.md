# GitHub Self-Hosted Runner on AWS with Docker

This project sets up a GitHub Actions self-hosted runner on AWS EC2 with Docker support, demonstrating how to run CI/CD workflows in custom containers.

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Setup Instructions](#setup-instructions)
- [Understanding Self-Hosted Runners vs Container Jobs](#understanding-self-hosted-runners-vs-container-jobs)
- [Testing the Setup](#testing-the-setup)
- [Troubleshooting](#troubleshooting)
- [Cleanup](#cleanup)

## 🎯 Overview

This project demonstrates:

1. **Infrastructure as Code**: Terraform to provision AWS resources (VPC, EC2, security groups)
2. **Self-Hosted Runner**: GitHub Actions runner running on AWS EC2
3. **Docker Integration**: Running workflow jobs inside Docker containers
4. **CI/CD Pipeline**: Automated testing of a Node.js application

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        GitHub                                │
│  ┌───────────────────────────────────────────────────────┐ │
│  │            Your Repository                             │ │
│  │  - .github/workflows/*.yml                            │ │
│  └───────────────────────────────────────────────────────┘ │
└────────────────────────┬────────────────────────────────────┘
                         │ Communicates
                         │
┌────────────────────────▼────────────────────────────────────┐
│                    AWS Cloud                                 │
│  ┌──────────────────────────────────────────────────────┐  │
│  │              Custom VPC (10.0.0.0/16)                │  │
│  │  ┌────────────────────────────────────────────────┐ │  │
│  │  │   Public Subnet (10.0.1.0/24)                  │ │  │
│  │  │                                                 │ │  │
│  │  │   ┌─────────────────────────────────────────┐ │ │  │
│  │  │   │  EC2 Instance (t3.medium)               │ │ │  │
│  │  │   │                                          │ │ │  │
│  │  │   │  ├─ GitHub Actions Runner (Service)     │ │ │  │
│  │  │   │  ├─ Docker Engine                       │ │ │  │
│  │  │   │  └─ Containers (Node.js, etc.)          │ │ │  │
│  │  │   └─────────────────────────────────────────┘ │ │  │
│  │  └────────────────────────────────────────────────┘ │  │
│  │             │                                         │  │
│  │  ┌──────────▼──────────┐                             │  │
│  │  │  Internet Gateway   │                             │  │
│  │  └─────────────────────┘                             │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## 📦 Prerequisites

### Required Tools

- **Terraform** (>= 1.0): [Install Guide](https://developer.hashicorp.com/terraform/downloads)
- **AWS CLI**: [Install Guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- **Git**: [Install Guide](https://git-scm.com/downloads)
- **GitHub Account** with a repository

### AWS Requirements

- AWS account with appropriate permissions (VPC, EC2, IAM)
- AWS credentials configured (`aws configure`)

### GitHub Requirements

- A GitHub repository where you'll run the workflows
- GitHub Personal Access Token with `repo` scope
  - Generate at: https://github.com/settings/tokens
  - Required permissions: `repo` (full control of private repositories)

### SSH Key Pair

Generate an SSH key pair if you don't have one:

```bash
ssh-keygen -t rsa -b 4096 -C "your-email@example.com" -f ~/.ssh/github-runner
```

## 🚀 Setup Instructions

### Step 1: Clone This Repository

```bash
git clone <your-repo-url>
cd customrunner
```

### Step 2: Configure Terraform Variables

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your values:

```hcl
aws_region        = "us-east-1"
project_name      = "github-runner"
instance_type     = "t3.medium"

# Your SSH public key content
ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2E... your-email@example.com"

# GitHub Personal Access Token
github_token = "ghp_YourPersonalAccessTokenHere"

# Your GitHub repository URL
github_repo_url = "https://github.com/yourusername/yourrepo"

# Runner name
runner_name = "aws-docker-runner-01"

# Restrict SSH to your IP (recommended)
ssh_allowed_ips = ["YOUR_PUBLIC_IP/32"]
```

**Important**: Get your public IP:
```bash
curl ifconfig.me
```

### Step 3: Update AMI ID (Optional)

The default AMI is for `us-east-1`. If using a different region, find the Ubuntu 22.04 LTS AMI:

- Visit: https://cloud-images.ubuntu.com/locator/ec2/
- Search for: `22.04 LTS` + your region
- Copy the AMI ID to `terraform.tfvars`

### Step 4: Initialize and Apply Terraform

```bash
# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply the configuration
terraform apply
```

Type `yes` when prompted. This will:
- Create a VPC with public subnet
- Launch an EC2 instance
- Install Docker
- Download and configure GitHub Actions runner
- Start the runner as a service

**Note**: This takes about 5-10 minutes.

### Step 5: Verify the Runner

After Terraform completes:

1. Get the runner's public IP:
   ```bash
   terraform output runner_public_ip
   ```

2. SSH into the instance:
   ```bash
   ssh -i ~/.ssh/github-runner ubuntu@<RUNNER_PUBLIC_IP>
   ```

3. Check runner status:
   ```bash
   sudo systemctl status actions.runner.*
   ```

4. Check Docker:
   ```bash
   docker --version
   docker ps
   ```

5. Run verification script:
   ```bash
   /home/runner/verify-setup.sh
   ```

6. Check GitHub:
   - Go to your repository
   - Navigate to: `Settings` → `Actions` → `Runners`
   - You should see your runner listed as "Idle"

### Step 6: Push Sample App to GitHub

```bash
cd /Users/balajibr/Desktop/customrunner

# Initialize git if not already done
git init
git add .
git commit -m "Initial commit: Self-hosted runner setup"

# Add your GitHub remote (use your repo URL)
git remote add origin https://github.com/yourusername/yourrepo.git
git branch -M main
git push -u origin main
```

### Step 7: Watch the Workflow Run

1. Go to your repository on GitHub
2. Click on the "Actions" tab
3. You should see the workflows running:
   - "Simple Test Workflow"
   - "CI with Self-Hosted Runner (Docker)"

## 🔍 Understanding Self-Hosted Runners vs Container Jobs

See [CONCEPTS.md](./CONCEPTS.md) for a detailed explanation of:
- What is a self-hosted runner?
- What are container jobs?
- How they work together
- Use cases and benefits

## 🧪 Testing the Setup

### Test 1: Simple Workflow

The `simple-test.yml` workflow tests basic functionality:

```bash
# Trigger manually from GitHub UI
# Actions → Simple Test Workflow → Run workflow
```

### Test 2: Node.js Tests in Docker

The `ci-docker.yml` workflow runs comprehensive tests:

```bash
# Automatically triggered on push to main/master
git commit --allow-empty -m "Trigger workflow"
git push
```

### Test 3: Local Testing

SSH into the runner and test Docker:

```bash
ssh -i ~/.ssh/github-runner ubuntu@<RUNNER_PUBLIC_IP>

# Run a test container
docker run --rm node:18-alpine node --version

# Check runner logs
sudo journalctl -u actions.runner.* -f
```

## 🔧 Troubleshooting

### Runner Not Appearing in GitHub

1. Check runner service status:
   ```bash
   sudo systemctl status actions.runner.*
   ```

2. Check logs:
   ```bash
   sudo journalctl -u actions.runner.* -n 50
   ```

3. Verify registration token is valid (tokens expire after 1 hour)

### Workflow Not Running

1. Verify runner is "Idle" in GitHub (not "Offline")
2. Check workflow file syntax
3. Ensure workflow uses `runs-on: self-hosted`

### Docker Permission Issues

```bash
# Add runner user to docker group
sudo usermod -aG docker runner

# Restart runner service
sudo systemctl restart actions.runner.*
```

### SSH Connection Issues

1. Verify security group allows your IP:
   ```bash
   terraform apply -refresh-only
   ```

2. Check SSH key permissions:
   ```bash
   chmod 600 ~/.ssh/github-runner
   ```

### View User Data Logs

```bash
# SSH into instance
ssh -i ~/.ssh/github-runner ubuntu@<RUNNER_PUBLIC_IP>

# View user-data execution log
sudo cat /var/log/user-data.log
```

## 🧹 Cleanup

When you're done testing, destroy all resources to avoid AWS charges:

```bash
cd terraform

# Destroy all resources
terraform destroy
```

Type `yes` when prompted.

**Note**: This will:
- Terminate the EC2 instance
- Delete the VPC and all networking components
- Remove the runner from GitHub automatically

## 📊 Cost Estimation

Approximate AWS costs (us-east-1):

- **t3.medium** EC2 instance: ~$0.0416/hour (~$30/month if running 24/7)
- **EBS Storage** (30 GB): ~$3/month
- **Data Transfer**: Usually free for outbound to GitHub

**Total**: ~$33/month if running continuously

**Cost Saving Tips**:
- Stop the instance when not in use
- Use smaller instance type (t3.small) if sufficient
- Use EC2 Spot Instances for non-production

## 🎓 Learning Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Self-Hosted Runners Guide](https://docs.github.com/en/actions/hosting-your-own-runners)
- [Running Jobs in Containers](https://docs.github.com/en/actions/using-jobs/running-jobs-in-a-container)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

## 📝 Next Steps

1. **Add more tests** to the sample app
2. **Configure webhook** for real-time workflow triggers
3. **Add secrets** for sensitive data
4. **Scale runners** using auto-scaling groups
5. **Implement monitoring** with CloudWatch
6. **Add deployment** stages to your workflow

## 🤝 Contributing

Feel free to open issues or submit pull requests!

## 📄 License

MIT License - feel free to use this for learning and production use.

