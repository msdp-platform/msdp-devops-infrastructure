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
      subscription_id    = "<REPLACE-SUB-ID>"
      tfstate_rg         = "rg-terraform-state"
      tfstate_sa         = "stterraformstate"
      tfstate_container  = "tfstate"
      network_state_key  = "infrastructure/environment/dev/azure/network/terraform.tfstate"
      aks_name           = "aks-dev"
      resource_group     = "rg-aks-dev"
      location           = "uksouth"
      kubernetes_version = null # Use latest stable
      system_vm          = "Standard_D2as_v5"
      system_count       = 1
      user_vm            = "Standard_D4as_v5"
      user_spot          = true
      min_count          = 0
      max_count          = 5
    }
  }

  # Resolve configuration from variables or environment map
  resolved = {
    subscription_id    = var.subscription_id != "" ? var.subscription_id : local.envs[var.env].subscription_id
    tfstate_rg         = local.envs[var.env].tfstate_rg
    tfstate_sa         = local.envs[var.env].tfstate_sa
    tfstate_container  = local.envs[var.env].tfstate_container
    network_state_key  = local.envs[var.env].network_state_key
    aks_name           = local.envs[var.env].aks_name
    resource_group     = local.envs[var.env].resource_group
    location           = local.envs[var.env].location
    kubernetes_version = local.envs[var.env].kubernetes_version
    system_vm          = local.envs[var.env].system_vm
    system_count       = local.envs[var.env].system_count
    user_vm            = local.envs[var.env].user_vm
    user_spot          = local.envs[var.env].user_spot
    min_count          = local.envs[var.env].min_count
    max_count          = local.envs[var.env].max_count
  }
}
