# OPTIONAL: Use AWS Secrets Manager for GitHub PAT
# This is more secure for production environments

# Uncomment and use this instead of passing github_token directly

# Store GitHub PAT in Secrets Manager (do this once manually)
# aws secretsmanager create-secret \
#   --name github-runner/pat \
#   --secret-string "ghp_your_token_here"

# Reference the secret in Terraform
# DISABLED - Uncomment when you create the secret in AWS
/*
data "aws_secretsmanager_secret" "github_pat" {
  name = "github-runner/pat"
}

data "aws_secretsmanager_secret_version" "github_pat" {
  secret_id = data.aws_secretsmanager_secret.github_pat.id
}
*/

# Add policy to allow EC2 to read the secret
# DISABLED - Uncomment when you create the secret in AWS
/*
resource "aws_iam_role_policy" "secrets_access" {
  name = "${var.project_name}-secrets-access"
  role = aws_iam_role.runner_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = data.aws_secretsmanager_secret.github_pat.arn
      }
    ]
  })
}
*/

# Modify user_data to fetch from Secrets Manager instead
# In main.tf, change user_data to:
# user_data = templatefile("${path.module}/user-data-secrets.sh", {
#   secret_arn      = data.aws_secretsmanager_secret.github_pat.arn
#   github_repo_url = var.github_repo_url
#   runner_name     = var.runner_name
# })

