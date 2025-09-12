variable "env" {
  description = "Environment name"
  type        = string
}

variable "subscription_id" {
  description = "Azure subscription ID (optional, can be set via environment variable)"
  type        = string
  default     = ""
}

# Optional inputs for fallback lookups
variable "resource_group" {
  description = "Resource group name for fallback subnet lookup"
  type        = string
  default     = ""
}

variable "vnet_name" {
  description = "Virtual network name for fallback subnet lookup"
  type        = string
  default     = ""
}

variable "subnet_name" {
  description = "Subnet name for fallback subnet lookup"
  type        = string
  default     = ""
}

variable "subnet_tags" {
  description = "Tags for tag-based subnet lookup"
  type        = map(string)
  default     = { role = "aks" }
}

variable "use_remote_state" {
  description = "Whether to use remote state for subnet resolution"
  type        = bool
  default     = true
}

locals {
  # Load config paths
  config_paths = yamldecode(file("${path.module}/../../../../config/local.yaml")).paths

  envs = {
    dev = {
      subscription_id = "<REPLACE-SUBSCRIPTION-ID>"
      # Remote state backend for reading Network outputs
      tfstate_rg        = "<TFSTATE-RG>"
      tfstate_sa        = "<TFSTATE-SA>"
      tfstate_container = "<TFSTATE-CONTAINER>"
      network_state_key = "network/dev.tfstate"

      aks_name           = "aks-dev-01"
      resource_group     = "rg-shared-dev"
      location           = "uksouth"
      kubernetes_version = "1.29.7"

      system_vm    = "Standard_B2s"
      system_count = 1

      user_vm   = "Standard_D4s_v5"
      user_spot = true
      min_count = 0
      max_count = 6
    }
  }

  resolved = {
    subscription_id   = var.subscription_id != "" ? var.subscription_id : local.envs[var.env].subscription_id
    tfstate_rg        = local.envs[var.env].tfstate_rg
    tfstate_sa        = local.envs[var.env].tfstate_sa
    tfstate_container = local.envs[var.env].tfstate_container
    network_state_key = local.envs[var.env].network_state_key

    aks_name           = local.envs[var.env].aks_name
    resource_group     = local.envs[var.env].resource_group
    location           = local.envs[var.env].location
    kubernetes_version = local.envs[var.env].kubernetes_version

    system_vm    = local.envs[var.env].system_vm
    system_count = local.envs[var.env].system_count

    user_vm   = local.envs[var.env].user_vm
    user_spot = local.envs[var.env].user_spot
    min_count = local.envs[var.env].min_count
    max_count = local.envs[var.env].max_count
  }
}
