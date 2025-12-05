output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.runner_vpc.id
}

output "runner_public_ip" {
  description = "Public IP address of the GitHub runner"
  value       = aws_instance.github_runner.public_ip
}

output "runner_instance_id" {
  description = "Instance ID of the GitHub runner"
  value       = aws_instance.github_runner.id
}

output "ssh_command" {
  description = "SSH command to connect to the runner"
  value       = "ssh -i ~/.ssh/your-key.pem ubuntu@${aws_instance.github_runner.public_ip}"
}

output "security_group_id" {
  description = "Security group ID"
  value       = aws_security_group.runner_sg.id
}

