# Terraform version constraints for development environment

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14"
    }
  }

  # Uncomment and configure for remote state
  # backend "s3" {
  #   bucket = "your-terraform-state-bucket"
  #   key    = "dev/eks-blueprint/terraform.tfstate"
  #   region = "us-west-2"
  #   
  #   # Enable state locking
  #   dynamodb_table = "terraform-state-lock"
  #   encrypt        = true
  # }
}
