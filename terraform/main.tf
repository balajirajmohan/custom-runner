terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# VPC
resource "aws_vpc" "runner_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "runner_igw" {
  vpc_id = aws_vpc.runner_vpc.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# Public Subnet
resource "aws_subnet" "runner_public_subnet" {
  vpc_id                  = aws_vpc.runner_vpc.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet"
  }
}

# Route Table
resource "aws_route_table" "runner_public_rt" {
  vpc_id = aws_vpc.runner_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.runner_igw.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

# Route Table Association
resource "aws_route_table_association" "runner_public_rta" {
  subnet_id      = aws_subnet.runner_public_subnet.id
  route_table_id = aws_route_table.runner_public_rt.id
}

# Security Group for Runner
resource "aws_security_group" "runner_sg" {
  name        = "${var.project_name}-runner-sg"
  description = "Security group for GitHub self-hosted runner"
  vpc_id      = aws_vpc.runner_vpc.id

  # SSH access
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_allowed_ips
  }

  # Outbound internet access
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-runner-sg"
  }
}

# IAM Role for EC2
resource "aws_iam_role" "runner_role" {
  name = "${var.project_name}-runner-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-runner-role"
  }
}

# IAM Policy for SSM (optional - for Session Manager access)
resource "aws_iam_role_policy_attachment" "runner_ssm" {
  role       = aws_iam_role.runner_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "runner_profile" {
  name = "${var.project_name}-runner-profile"
  role = aws_iam_role.runner_role.name
}

# EC2 Key Pair (you'll need to create this separately or import your own)
resource "aws_key_pair" "runner_key" {
  key_name   = "${var.project_name}-key"
  public_key = var.ssh_public_key

  tags = {
    Name = "${var.project_name}-key"
  }
}

# EC2 Instance for GitHub Runner
resource "aws_instance" "github_runner" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.runner_public_subnet.id
  vpc_security_group_ids = [aws_security_group.runner_sg.id]
  key_name               = aws_key_pair.runner_key.key_name
  iam_instance_profile   = aws_iam_instance_profile.runner_profile.name

  # Increased root volume for Docker images
  root_block_device {
    volume_size           = 30
    volume_type           = "gp3"
    delete_on_termination = true
  }

  user_data = templatefile("${path.module}/user-data.sh", {
    github_token    = var.github_token
    github_repo_url = var.github_repo_url
    runner_name     = var.runner_name
  })

  tags = {
    Name = "${var.project_name}-runner"
  }

  lifecycle {
    ignore_changes = [ami]
  }
}

