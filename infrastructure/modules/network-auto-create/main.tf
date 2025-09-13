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
  validation {
    condition     = alltrue([for cidr in var.vnet_address_space : can(cidrnetmask(cidr))])
    error_message = "All vnet_address_space entries must be valid CIDR blocks."
  }
}

variable "subnet_name" {
  type        = string
  description = "Subnet name"
}

variable "subnet_address_prefix" {
  type        = string
  description = "Address prefix for subnet"
  validation {
    condition     = can(cidrnetmask(var.subnet_address_prefix))
    error_message = "subnet_address_prefix must be a valid CIDR block."
  }
}

variable "create_resource_group" {
  type        = bool
  description = "Create resource group if it doesn't exist"
  default     = false
}

variable "tags" {
  type        = map(string)
  description = "Resource tags"
  default     = {}
}

# Check and create resource group
resource "azurerm_resource_group" "this" {
  count    = var.create_resource_group ? 1 : 0
  name     = var.resource_group
  location = var.location
  tags     = var.tags

  lifecycle {
    prevent_destroy = true
  }
}

# Get the resource group (existing or created)
data "azurerm_resource_group" "this" {
  name = var.resource_group
  depends_on = [azurerm_resource_group.this]
}

# Check if VNet exists
data "azurerm_resources" "vnet_check" {
  type                = "Microsoft.Network/virtualNetworks"
  resource_group_name = var.resource_group
  name                = var.vnet_name
  depends_on          = [azurerm_resource_group.this]
}

# Create VNet if it doesn't exist
resource "azurerm_virtual_network" "this" {
  count               = local.vnet_exists ? 0 : 1
  name                = var.vnet_name
  location            = local.rg_location
  resource_group_name = var.resource_group
  address_space       = var.vnet_address_space
  tags                = var.tags
  depends_on          = [azurerm_resource_group.this]

  lifecycle {
    prevent_destroy = true
  }
}

# Get the VNet (existing or created)
data "azurerm_virtual_network" "this" {
  name                = var.vnet_name
  resource_group_name = var.resource_group
  depends_on          = [azurerm_virtual_network.this]
}

# Check if subnet exists
data "azurerm_resources" "subnet_check" {
  type                = "Microsoft.Network/virtualNetworks/subnets"
  resource_group_name = var.resource_group
  name                = "${var.vnet_name}/${var.subnet_name}"
  depends_on          = [azurerm_virtual_network.this]
}

locals {
  rg_location   = data.azurerm_resource_group.this.location
  vnet_exists   = length(data.azurerm_resources.vnet_check.resources) > 0
  subnet_exists = length(data.azurerm_resources.subnet_check.resources) > 0
}

# Create subnet if it doesn't exist
resource "azurerm_subnet" "this" {
  count                = local.subnet_exists ? 0 : 1
  name                 = var.subnet_name
  resource_group_name  = var.resource_group
  virtual_network_name = var.vnet_name
  address_prefixes     = [var.subnet_address_prefix]
  depends_on           = [azurerm_virtual_network.this]

  lifecycle {
    prevent_destroy = true
  }
}

# Get the subnet (existing or created)
data "azurerm_subnet" "this" {
  name                 = var.subnet_name
  virtual_network_name = var.vnet_name
  resource_group_name  = var.resource_group
  depends_on           = [azurerm_subnet.this]
}

# Outputs
output "subnet_id" {
  value       = data.azurerm_subnet.this.id
  description = "The ID of the subnet (existing or newly created)"
}

output "vnet_id" {
  value       = data.azurerm_virtual_network.this.id
  description = "The ID of the VNet (existing or newly created)"
}

output "resource_group_id" {
  value       = data.azurerm_resource_group.this.id
  description = "The ID of the resource group"
}

output "created_resources" {
  value = {
    resource_group = var.create_resource_group && length(azurerm_resource_group.this) > 0
    vnet           = !local.vnet_exists
    subnet         = !local.subnet_exists
  }
  description = "Map indicating which resources were created"
}
