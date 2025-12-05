#!/bin/bash
set -e

# Log all output
exec > >(tee /var/log/user-data.log)
exec 2>&1

echo "Starting GitHub Runner setup..."

# Update system
apt-get update
apt-get upgrade -y

# Install required packages
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    jq \
    git

# Install Docker
echo "Installing Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Start and enable Docker
systemctl start docker
systemctl enable docker

# Create a runner user
useradd -m -s /bin/bash runner
usermod -aG docker runner

# Allow runner user to use Docker without sudo
echo "runner ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Create actions-runner directory
mkdir -p /home/runner/actions-runner
cd /home/runner/actions-runner

# Download the latest runner package
echo "Downloading GitHub Actions runner..."
RUNNER_VERSION=$(curl -s https://api.github.com/repos/actions/runner/releases/latest | jq -r .tag_name | sed 's/v//')
curl -o actions-runner-linux-x64-$${RUNNER_VERSION}.tar.gz -L https://github.com/actions/runner/releases/download/v$${RUNNER_VERSION}/actions-runner-linux-x64-$${RUNNER_VERSION}.tar.gz

# Extract the installer
tar xzf ./actions-runner-linux-x64-$${RUNNER_VERSION}.tar.gz

# Set ownership
chown -R runner:runner /home/runner/actions-runner

# Get registration token from GitHub
echo "Getting registration token from GitHub..."
GITHUB_TOKEN="${github_token}"
REPO_URL="${github_repo_url}"

# Extract owner and repo from URL
REPO_PATH=$(echo $REPO_URL | sed 's/https:\/\/github.com\///')
REGISTRATION_TOKEN=$(curl -s -X POST \
    -H "Authorization: token $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    "https://api.github.com/repos/$REPO_PATH/actions/runners/registration-token" | jq -r .token)

# Configure the runner
echo "Configuring GitHub Actions runner..."
su - runner -c "cd /home/runner/actions-runner && ./config.sh --url $REPO_URL --token $REGISTRATION_TOKEN --name ${runner_name} --labels docker,aws,self-hosted --work _work --unattended"

# Install and start the runner as a service
echo "Installing runner as a service..."
cd /home/runner/actions-runner
./svc.sh install runner
./svc.sh start

# Verify Docker installation
echo "Verifying Docker installation..."
docker --version
docker ps

echo "GitHub Runner setup complete!"
echo "Runner name: ${runner_name}"
echo "Repository: ${github_repo_url}"

# Create a test script to verify setup
cat > /home/runner/verify-setup.sh << 'EOF'
#!/bin/bash
echo "=== System Information ==="
uname -a
echo ""
echo "=== Docker Version ==="
docker --version
echo ""
echo "=== Docker Status ==="
systemctl status docker --no-pager
echo ""
echo "=== Runner Service Status ==="
systemctl status actions.runner.* --no-pager
echo ""
echo "=== Disk Space ==="
df -h
EOF

chmod +x /home/runner/verify-setup.sh
chown runner:runner /home/runner/verify-setup.sh

echo "Setup script completed successfully!"

