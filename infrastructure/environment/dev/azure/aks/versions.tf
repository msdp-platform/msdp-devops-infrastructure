terraform {
  required_version = ">= 1.3"

  backend "s3" {}

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.110"
    }
  }
}

provider "azurerm" {
  features {}
}
