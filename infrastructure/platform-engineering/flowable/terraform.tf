# Terraform configuration for Flowable BPM Platform

terraform {
  required_version = ">= 1.5"
  
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.15"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.24"
    }
  }

  backend "s3" {
    # Backend configuration will be provided by GitHub Actions
    # via -backend-config parameters (bucket, region, dynamodb_table, etc.)
  }
}

# Provider configurations
provider "kubernetes" {
  # Configuration will be provided by kubeconfig
}

provider "helm" {
  kubernetes {
    # Configuration will be provided by kubeconfig
  }
}
