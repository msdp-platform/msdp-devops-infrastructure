variable "env" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "subscription_id" {
  description = "Azure subscription ID (optional, can be set via environment variable)"
  type        = string
  default     = ""
}

# Environment configuration map
locals {
  envs = {
    dev = {
      subscription_id = "<REPLACE-SUB-ID>"
      location        = "uksouth"
      resource_group  = "rg-shared-dev"
      vnet_name       = "vnet-shared-dev"
      vnet_cidr       = "10.50.0.0/16"
      subnet_name     = "snet-aks-dev"
      subnet_cidr     = "10.50.1.0/24"
      subnet_tags = {
        role = "aks"
      }
    }
  }

  # Resolve configuration from variables or environment map
  resolved = {
    subscription_id = var.subscription_id != "" ? var.subscription_id : local.envs[var.env].subscription_id
    location        = local.envs[var.env].location
    resource_group  = local.envs[var.env].resource_group
    vnet_name       = local.envs[var.env].vnet_name
    vnet_cidr       = local.envs[var.env].vnet_cidr
    subnet_name     = local.envs[var.env].subnet_name
    subnet_cidr     = local.envs[var.env].subnet_cidr
    subnet_tags     = local.envs[var.env].subnet_tags
  }
}
