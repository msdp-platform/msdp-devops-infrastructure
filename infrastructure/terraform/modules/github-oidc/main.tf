# GitHub OIDC Provider and IAM Roles for AWS Authentication

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Data sources
data "aws_caller_identity" "current" {}

# Local values
locals {
  account_id        = data.aws_caller_identity.current.account_id
  oidc_provider_arn = "arn:aws:iam::${local.account_id}:oidc-provider/token.actions.githubusercontent.com"
}

# GitHub OIDC Identity Provider
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com",
  ]

  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
  ]

  tags = merge(var.tags, {
    Name    = "github-actions-oidc"
    Purpose = "GitHub Actions authentication"
  })
}

# IAM Role for GitHub Actions
resource "aws_iam_role" "github_actions" {
  name = "${var.role_name_prefix}-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_org}/${var.github_repo}:*"
          }
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name    = "${var.role_name_prefix}-Role"
    Purpose = "GitHub Actions authentication"
  })
}

# IAM Policy for GitHub Actions
resource "aws_iam_policy" "github_actions" {
  name = "${var.role_name_prefix}-Policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:*",
          "ec2:*",
          "iam:*",
          "vpc:*",
          "sqs:*",
          "events:*",
          "cloudwatch:*",
          "logs:*",
          "route53:*",
          "acm:*",
          "secretsmanager:*",
          "ssm:*",
          "s3:*",
          "rds:*",
          "elasticloadbalancing:*",
          "autoscaling:*",
          "application-autoscaling:*",
          "kms:*",
          "sts:*"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(var.tags, {
    Name    = "${var.role_name_prefix}-Policy"
    Purpose = "GitHub Actions permissions"
  })
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "github_actions" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.github_actions.arn
}

# S3 Bucket for Terraform state
resource "aws_s3_bucket" "terraform_state" {
  count  = var.create_terraform_backend ? 1 : 0
  bucket = "${var.terraform_bucket_name}-${random_string.bucket_suffix[0].result}"

  tags = merge(var.tags, {
    Name    = "terraform-state"
    Purpose = "Terraform backend storage"
  })
}

resource "random_string" "bucket_suffix" {
  count   = var.create_terraform_backend ? 1 : 0
  length  = 8
  special = false
  upper   = false
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  count  = var.create_terraform_backend ? 1 : 0
  bucket = aws_s3_bucket.terraform_state[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_encryption" "terraform_state" {
  count  = var.create_terraform_backend ? 1 : 0
  bucket = aws_s3_bucket.terraform_state[0].id

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  count  = var.create_terraform_backend ? 1 : 0
  bucket = aws_s3_bucket.terraform_state[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
