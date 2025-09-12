terraform {
  required_version = ">= 1.5.0"

  backend "s3" {}

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "= 4.44.0"
    }
  }
}

