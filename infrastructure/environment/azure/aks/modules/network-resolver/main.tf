terraform {
  required_version = ">= 1.6"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.9"
    }
  }
}

variable "resource_group" {
  type        = string
  description = "Resource group name"
}

variable "location" {
  type        = string
  description = "Azure region"
}

variable "vnet_name" {
  type        = string
  description = "Virtual network name"
}

variable "vnet_address_space" {
  type        = list(string)
  description = "Address space for VNet"
}

variable "subnet_name" {
  type        = string
  description = "Subnet name"
}

variable "subnet_address_prefix" {
  type        = string
  description = "Address prefix for subnet"
}

variable "tags" {
  type        = map(string)
  description = "Resource tags"
  default     = {}
}

# Check if resource group exists
data "azurerm_resource_group" "check" {
  count = 1
  name  = var.resource_group
}

locals {
  rg_exists = length(try(data.azurerm_resource_group.check[0].id, "")) > 0
}

# Create resource group if needed
resource "azurerm_resource_group" "new" {
  count    = local.rg_exists ? 0 : 1
  name     = var.resource_group
  location = var.location
  tags     = var.tags
}

locals {
  actual_rg_name     = var.resource_group
  actual_rg_location = local.rg_exists ? data.azurerm_resource_group.check[0].location : azurerm_resource_group.new[0].location
}

# Check if VNet exists
data "azurerm_virtual_network" "check" {
  count               = 1
  name                = var.vnet_name
  resource_group_name = local.actual_rg_name
  
  depends_on = [azurerm_resource_group.new]
}

locals {
  vnet_exists = length(try(data.azurerm_virtual_network.check[0].id, "")) > 0
}

# Create VNet if needed
resource "azurerm_virtual_network" "new" {
  count               = local.vnet_exists ? 0 : 1
  name                = var.vnet_name
  location            = local.actual_rg_location
  resource_group_name = local.actual_rg_name
  address_space       = var.vnet_address_space
  tags                = var.tags
  
  depends_on = [azurerm_resource_group.new]
}

locals {
  actual_vnet_name = var.vnet_name
}

# Check if subnet exists
data "azurerm_subnet" "check" {
  count                = 1
  name                 = var.subnet_name
  virtual_network_name = local.actual_vnet_name
  resource_group_name  = local.actual_rg_name
  
  depends_on = [azurerm_virtual_network.new]
}

locals {
  subnet_exists = length(try(data.azurerm_subnet.check[0].id, "")) > 0
}

# Create subnet if needed
resource "azurerm_subnet" "new" {
  count                = local.subnet_exists ? 0 : 1
  name                 = var.subnet_name
  resource_group_name  = local.actual_rg_name
  virtual_network_name = local.actual_vnet_name
  address_prefixes     = [var.subnet_address_prefix]
  
  depends_on = [azurerm_virtual_network.new]
}

# Output the subnet ID
output "subnet_id" {
  value = local.subnet_exists ? data.azurerm_subnet.check[0].id : azurerm_subnet.new[0].id
  description = "The ID of the subnet (existing or newly created)"
}

output "vnet_id" {
  value = local.vnet_exists ? data.azurerm_virtual_network.check[0].id : azurerm_virtual_network.new[0].id
  description = "The ID of the VNet (existing or newly created)"
}

output "resource_group_id" {
  value = local.rg_exists ? data.azurerm_resource_group.check[0].id : azurerm_resource_group.new[0].id
  description = "The ID of the resource group (existing or newly created)"
}

output "created_resources" {
  value = {
    resource_group = !local.rg_exists
    vnet           = !local.vnet_exists
    subnet         = !local.subnet_exists
  }
  description = "Map indicating which resources were created"
}