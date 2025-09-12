resource "azurerm_resource_group" "rg" {
  name     = var.resource_group
  location = var.location
  tags     = var.tags
}

resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = local.normalized_address_space
  tags                = var.tags
}

resource "azurerm_network_security_group" "nsg" {
  for_each            = { for s in local.effective_subnets : s.name => s if try(s.nsg_name != null && s.nsg_name != "", false) }
  name                = each.value.nsg_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags
}

resource "azurerm_subnet" "subnets" {
  for_each             = { for s in local.effective_subnets : s.name => s }
  name                 = each.value.name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [each.value.cidr]
}

resource "azurerm_subnet_network_security_group_association" "assoc" {
  for_each                  = { for s in local.effective_subnets : s.name => s if try(s.nsg_name != null && s.nsg_name != "", false) }
  subnet_id                 = azurerm_subnet.subnets[each.key].id
  network_security_group_id = azurerm_network_security_group.nsg[each.key].id
}
