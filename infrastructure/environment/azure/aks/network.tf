# Smart network resource management
# This module can work in two modes:
# 1. Lookup mode (default): Use existing VNet/Subnet, fail if they don't exist
# 2. Managed mode: Create VNet/Subnet if they don't exist, use existing if they do

variable "manage_network" {
  type        = bool
  description = "If true, create VNet/Subnet if they don't exist. If false, they must already exist."
  default     = false
}

variable "create_resource_group" {
  type        = bool
  description = "If true and manage_network is true, create resource group if it doesn't exist"
  default     = false
}

variable "vnet_address_space" {
  type        = list(string)
  description = "Address space for VNet (used only when creating)"
  default     = ["10.60.0.0/16"]
}

variable "subnet_address_prefix" {
  type        = string
  description = "Address prefix for subnet (used only when creating)"
  default     = "10.60.1.0/24"
}

# When manage_network = true, use the auto-create module
module "network_auto_create" {
  source = "../../../modules/network-auto-create"
  count  = var.manage_network ? 1 : 0

  resource_group        = var.resource_group
  location              = var.location
  vnet_name             = var.vnet_name
  vnet_address_space    = var.vnet_address_space
  subnet_name           = var.subnet_name
  subnet_address_prefix = var.subnet_address_prefix
  create_resource_group = var.create_resource_group
  tags                  = var.tags
}

# Determine the final subnet ID based on mode
locals {
  final_subnet_id = var.manage_network ? module.network_auto_create[0].subnet_id : local.effective_subnet_id
}

# Validation
resource "null_resource" "validate_network_config" {
  lifecycle {
    precondition {
      condition     = length(local.final_subnet_id) > 0
      error_message = "Failed to resolve subnet. Either set manage_network=true to auto-create, or ensure the VNet '${var.vnet_name}' and subnet '${var.subnet_name}' exist in resource group '${var.resource_group}'."
    }
  }
}

# Output network status for visibility
output "network_status" {
  value = var.manage_network ? {
    mode              = "auto-create"
    resources_created = try(module.network_auto_create[0].created_resources, {})
    subnet_id         = local.final_subnet_id
  } : {
    mode      = "lookup-only"
    subnet_id = local.effective_subnet_id
  }
  description = "Network configuration status"
}