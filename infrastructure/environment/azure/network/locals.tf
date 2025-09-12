variable "global_config_path" {
  description = "Path to global config file"
  type        = string
  default     = "config/global.yaml"
}

variable "env_config_path" {
  description = "Path to environment config file"
  type        = string
  default     = "config/envs/dev.yaml"
}

locals {
  # Load config files
  global_config = yamldecode(file("${path.module}/../../../${var.global_config_path}"))
  env_config    = yamldecode(file("${path.module}/../../../${var.env_config_path}"))

  # Azure configuration with fallbacks
  az = {
    subscriptionId = local.env_config.azure.subscriptionId
    resourceGroup  = local.env_config.azure.resourceGroup
    aksName        = local.env_config.azure.aksName
    vnetName       = local.env_config.azure.vnetName
    subnetName     = local.env_config.azure.subnetName
    vnetCidr       = local.env_config.azure.vnetCidr
    subnetCidr     = local.env_config.azure.subnetCidr
  }

  global = local.global_config
}