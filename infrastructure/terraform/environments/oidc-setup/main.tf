# GitHub OIDC Setup Environment

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "local" {
    path = "terraform.tfstate"
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = "oidc-setup"
      Project     = "msdp"
      ManagedBy   = "terraform"
    }
  }
}

# GitHub OIDC Module
module "github_oidc" {
  source = "../../modules/github-oidc"

  github_org               = var.github_org
  github_repo              = var.github_repo
  role_name_prefix         = var.role_name_prefix
  create_terraform_backend = var.create_terraform_backend
  terraform_bucket_name    = var.terraform_bucket_name

  tags = {
    Environment = "oidc-setup"
    Project     = "msdp"
    ManagedBy   = "terraform"
  }
}
