# Centralized provider version constraints for MSDP DevOps Infrastructure
# This file defines the standard versions used across all environments

terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 6.12.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.44.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

# Provider configurations should be defined in environment-specific files
# This file only contains version constraints
