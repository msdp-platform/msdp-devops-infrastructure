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
  description = "Create resource group if it doesn't exist (module-managed RG). If false, RG must pre-exist."
  default     = true
}

variable "tags" {
  type        = map(string)
  description = "Resource tags"
  default     = {}
}

# Non-failing existence check for the Resource Group (does not 404 if missing)
# Lists across the subscription and filters by name
# Returns zero resources if not found

data "azurerm_resources" "rg_check" {
  type = "Microsoft.Resources/resourceGroups"
  name = var.resource_group
}

locals {
  rg_exists   = length(data.azurerm_resources.rg_check.resources) > 0
  rg_location = local.rg_exists ? data.azurerm_resources.rg_check.resources[0].location : var.location
}

# Conditionally create the Resource Group (only when missing and allowed)
resource "azurerm_resource_group" "this" {
  count    = (var.create_resource_group && !local.rg_exists) ? 1 : 0
  name     = var.resource_group
  location = var.location
  tags     = var.tags

  lifecycle {
    prevent_destroy = true
  }
}

# After RG exists (either pre-existing or created here), check for VNet existence
# This read is scoped to the RG and would 404 if RG didn't exist; ensure ordering

data "azurerm_resources" "vnet_check" {
  type = "Microsoft.Network/virtualNetworks"
}

locals {
  vnet_candidates = [
    for r in data.azurerm_resources.vnet_check.resources :
    r
    if lower(r.name) == lower(var.vnet_name)
    && (
      try(r.resource_group_name, "") == var.resource_group
      || can(regex("/resourceGroups/${var.resource_group}/", r.id))
    )
  ]
  vnet_exists = length(local.vnet_candidates) > 0
}

# Create VNet if it doesn't exist
resource "azurerm_virtual_network" "this" {
  count               = 1
  name                = var.vnet_name
  location            = local.rg_location
  resource_group_name = var.resource_group
  address_space       = var.vnet_address_space
  tags                = var.tags

  depends_on = [azurerm_resource_group.this]

  lifecycle {
    prevent_destroy = true
  }
}

# Get the VNet (existing or created)

data "azurerm_virtual_network" "this" {
  name                = var.vnet_name
  resource_group_name = var.resource_group

  depends_on = [azurerm_virtual_network.this]
}

# Check if subnet exists (after VNet is guaranteed to exist if module just created it)

data "azurerm_resources" "subnet_check" {
  type = "Microsoft.Network/virtualNetworks/subnets"
}

locals {
  subnet_candidates = [
    for r in data.azurerm_resources.subnet_check.resources :
    r
    if(
      try(r.resource_group_name, "") == var.resource_group
      || can(regex("/resourceGroups/${var.resource_group}/", r.id))
    )
    && can(regex("/virtualNetworks/${var.vnet_name}/subnets/${var.subnet_name}$", r.id))
  ]
  subnet_exists = length(local.subnet_candidates) > 0
}

# Create subnet if it doesn't exist
resource "azurerm_subnet" "this" {
  count                = 1
  name                 = var.subnet_name
  resource_group_name  = var.resource_group
  virtual_network_name = var.vnet_name
  address_prefixes     = [var.subnet_address_prefix]

  depends_on = [azurerm_virtual_network.this]

  lifecycle {
    prevent_destroy = true
  }
}

# Get the subnet (existing or created)

data "azurerm_subnet" "this" {
  name                 = var.subnet_name
  virtual_network_name = var.vnet_name
  resource_group_name  = var.resource_group

  depends_on = [azurerm_subnet.this]
}

# Outputs
locals {
  resource_group_id = local.rg_exists ? data.azurerm_resources.rg_check.resources[0].id : azurerm_resource_group.this[0].id
}

output "subnet_id" {
  value       = data.azurerm_subnet.this.id
  description = "The ID of the subnet (existing or newly created)"
}

output "vnet_id" {
  value       = data.azurerm_virtual_network.this.id
  description = "The ID of the VNet (existing or newly created)"
}

output "resource_group_id" {
  value       = local.resource_group_id
  description = "The ID of the resource group"
}

output "created_resources" {
  value = {
    resource_group = (var.create_resource_group && !local.rg_exists) && length(azurerm_resource_group.this) > 0
    vnet           = !local.vnet_exists
    subnet         = !local.subnet_exists
  }
  description = "Map indicating which resources were created"
}
