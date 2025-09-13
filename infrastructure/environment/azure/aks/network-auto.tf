# Intelligent network resource management
# This module can work in three modes:
# 1. Use existing resources (default)
# 2. Create missing resources (manage_network = true)
# 3. Fail if resources don't exist (manage_network = false)

variable "manage_network" {
  type        = bool
  description = "If true, create VNet/Subnet if they don't exist. If false, they must already exist."
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

# Module to check and optionally create network resources
module "network_resources" {
  source = "./modules/network-resolver"
  count  = var.manage_network ? 1 : 0

  resource_group        = var.resource_group
  location              = var.location
  vnet_name             = var.vnet_name
  vnet_address_space    = var.vnet_address_space
  subnet_name           = var.subnet_name
  subnet_address_prefix = var.subnet_address_prefix
  tags                  = var.tags
}

# Get the final subnet ID from either the module or data source
locals {
  resolved_subnet_id = var.manage_network ? module.network_resources[0].subnet_id : local.effective_subnet_id
  
  # Validation
  subnet_id_valid = length(local.resolved_subnet_id) > 0
}

# Validation resource
resource "null_resource" "validate_network" {
  lifecycle {
    precondition {
      condition     = local.subnet_id_valid
      error_message = "Failed to resolve subnet. Either set manage_network=true to auto-create, or ensure the VNet and subnet exist."
    }
  }
}

# Update the final subnet ID to use the resolved one
locals {
  final_subnet_id = local.resolved_subnet_id
}