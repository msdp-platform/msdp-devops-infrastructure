# Variables for OIDC Setup Environment

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "github_org" {
  description = "GitHub organization name"
  type        = string
  default     = "your-github-org"
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
  default     = "msdp-devops-infrastructure"
}

variable "role_name_prefix" {
  description = "Prefix for IAM role names"
  type        = string
  default     = "GitHubActions"
}

variable "create_terraform_backend" {
  description = "Whether to create S3 bucket for Terraform backend"
  type        = bool
  default     = true
}

variable "terraform_bucket_name" {
  description = "Name for Terraform state S3 bucket"
  type        = string
  default     = "msdp-terraform-state"
}
