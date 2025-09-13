# Smart network resource management
# Automatically creates missing network resources when manage_network = true

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

# Try to get existing resource group (for managed network mode)
data "azurerm_resource_group" "existing_rg" {
  count = var.manage_network ? 1 : 0
  name  = var.resource_group
}

# Create resource group if it doesn't exist and we're managing
resource "azurerm_resource_group" "managed_rg" {
  count    = var.manage_network && var.create_resource_group && !can(data.azurerm_resource_group.existing_rg[0].id) ? 1 : 0
  name     = var.resource_group
  location = var.location
  tags     = var.tags
}

locals {
  # Determine the actual resource group to use
  managed_rg_name = var.resource_group
  managed_rg_location = try(
    azurerm_resource_group.managed_rg[0].location,
    data.azurerm_resource_group.existing_rg[0].location,
    var.location
  )
}

# Try to get existing VNet
data "azurerm_virtual_network" "existing_vnet" {
  count               = var.manage_network ? 1 : 0
  name                = var.vnet_name
  resource_group_name = local.managed_rg_name
  
  depends_on = [azurerm_resource_group.managed_rg]
}

# Create VNet if it doesn't exist and we're managing
resource "azurerm_virtual_network" "managed_vnet" {
  count               = var.manage_network && !can(data.azurerm_virtual_network.existing_vnet[0].id) ? 1 : 0
  name                = var.vnet_name
  location            = local.managed_rg_location
  resource_group_name = local.managed_rg_name
  address_space       = var.vnet_address_space
  tags                = var.tags
  
  depends_on = [azurerm_resource_group.managed_rg]
}

# Try to get existing subnet
data "azurerm_subnet" "existing_subnet" {
  count                = var.manage_network ? 1 : 0
  name                 = var.subnet_name
  virtual_network_name = var.vnet_name
  resource_group_name  = local.managed_rg_name
  
  depends_on = [azurerm_virtual_network.managed_vnet]
}

# Create subnet if it doesn't exist and we're managing
resource "azurerm_subnet" "managed_subnet" {
  count                = var.manage_network && !can(data.azurerm_subnet.existing_subnet[0].id) ? 1 : 0
  name                 = var.subnet_name
  resource_group_name  = local.managed_rg_name
  virtual_network_name = var.vnet_name
  address_prefixes     = [var.subnet_address_prefix]
  
  depends_on = [azurerm_virtual_network.managed_vnet]
}

# Output the final subnet ID when managing network
locals {
  managed_subnet_id = var.manage_network ? coalesce(
    try(azurerm_subnet.managed_subnet[0].id, ""),
    try(data.azurerm_subnet.existing_subnet[0].id, "")
  ) : ""
  
  # Update the final subnet ID
  final_subnet_id = var.manage_network ? local.managed_subnet_id : local.effective_subnet_id
}

# Output what was created (useful for debugging)
output "network_management_status" {
  value = var.manage_network ? {
    mode                   = "managed"
    resource_group_created = length(azurerm_resource_group.managed_rg) > 0
    vnet_created          = length(azurerm_virtual_network.managed_vnet) > 0
    subnet_created        = length(azurerm_subnet.managed_subnet) > 0
    subnet_id             = local.managed_subnet_id
  } : {
    mode      = "lookup-only"
    subnet_id = local.effective_subnet_id
  }
  description = "Status of network resource management"
}