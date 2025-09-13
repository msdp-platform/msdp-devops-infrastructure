resource "azurerm_resource_group" "rg" {
  count    = var.manage_resource_group ? 1 : 0
  name     = var.resource_group
  location = var.location
  tags     = var.tags
}

data "azurerm_resource_group" "rg" {
  count = var.manage_resource_group ? 0 : 1
  name  = var.resource_group
}

resource "azurerm_virtual_network" "vnet" {
  count               = var.manage_vnet ? 1 : 0
  name                = var.vnet_name
  location            = var.manage_resource_group ? azurerm_resource_group.rg[0].location : data.azurerm_resource_group.rg[0].location
  resource_group_name = var.manage_resource_group ? azurerm_resource_group.rg[0].name     : data.azurerm_resource_group.rg[0].name
  address_space       = local.normalized_address_space
  tags                = var.tags
}

data "azurerm_virtual_network" "vnet" {
  count               = var.manage_vnet ? 0 : 1
  name                = var.vnet_name
  resource_group_name = var.manage_resource_group ? azurerm_resource_group.rg[0].name : data.azurerm_resource_group.rg[0].name
}

resource "azurerm_network_security_group" "nsg" {
  for_each            = { for s in local.effective_subnets : s.name => s if try(s.nsg_name != null && s.nsg_name != "", false) }
  name                = each.value.nsg_name
  location            = var.manage_resource_group ? azurerm_resource_group.rg[0].location : data.azurerm_resource_group.rg[0].location
  resource_group_name = var.manage_resource_group ? azurerm_resource_group.rg[0].name     : data.azurerm_resource_group.rg[0].name
  tags                = var.tags
}

resource "azurerm_subnet" "subnets" {
  for_each             = { for s in local.effective_subnets : s.name => s }
  name                 = each.value.name
  resource_group_name  = var.manage_resource_group ? azurerm_resource_group.rg[0].name : data.azurerm_resource_group.rg[0].name
  virtual_network_name = var.manage_vnet ? azurerm_virtual_network.vnet[0].name : data.azurerm_virtual_network.vnet[0].name
  address_prefixes     = [each.value.cidr]
}

resource "azurerm_subnet_network_security_group_association" "assoc" {
  for_each                  = { for s in local.effective_subnets : s.name => s if try(s.nsg_name != null && s.nsg_name != "", false) }
  subnet_id                 = azurerm_subnet.subnets[each.key].id
  network_security_group_id = azurerm_network_security_group.nsg[each.key].id
}
