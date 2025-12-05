variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name to prefix resources"
  type        = string
  default     = "github-runner"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "ssh_allowed_ips" {
  description = "List of IP addresses allowed to SSH"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # Change this to your IP for security
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "ami_id" {
  description = "AMI ID for Ubuntu 22.04 LTS (update based on your region)"
  type        = string
  # Ubuntu 22.04 LTS in us-east-1
  default     = "ami-0c7217cdde317cfec"
}

variable "ssh_public_key" {
  description = "SSH public key content for EC2 access"
  type        = string
  sensitive   = true
}

variable "github_token" {
  description = "GitHub Personal Access Token for runner registration"
  type        = string
  sensitive   = true
}

variable "github_repo_url" {
  description = "GitHub repository URL (e.g., https://github.com/username/repo)"
  type        = string
}

variable "runner_name" {
  description = "Name for the GitHub runner"
  type        = string
  default     = "aws-docker-runner"
}

