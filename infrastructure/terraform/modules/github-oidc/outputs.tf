# Outputs for GitHub OIDC Module

output "oidc_provider_arn" {
  description = "ARN of the GitHub OIDC provider"
  value       = aws_iam_openid_connect_provider.github.arn
}

output "github_actions_role_arn" {
  description = "ARN of the GitHub Actions IAM role"
  value       = aws_iam_role.github_actions.arn
}

output "github_actions_role_name" {
  description = "Name of the GitHub Actions IAM role"
  value       = aws_iam_role.github_actions.name
}

output "terraform_bucket_name" {
  description = "Name of the Terraform state S3 bucket"
  value       = var.create_terraform_backend ? aws_s3_bucket.terraform_state[0].bucket : null
}

output "terraform_bucket_arn" {
  description = "ARN of the Terraform state S3 bucket"
  value       = var.create_terraform_backend ? aws_s3_bucket.terraform_state[0].arn : null
}

output "github_secrets" {
  description = "GitHub secrets to add to repository"
  value = {
    AWS_ROLE_ARN          = aws_iam_role.github_actions.arn
    AWS_REGION            = "us-west-2"
    TERRAFORM_BUCKET_NAME = var.create_terraform_backend ? aws_s3_bucket.terraform_state[0].bucket : null
  }
}
