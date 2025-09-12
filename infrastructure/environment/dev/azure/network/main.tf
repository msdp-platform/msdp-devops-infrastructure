resource "azurerm_resource_group" "rg" {
  name     = local.resolved.resource_group
  location = local.resolved.location
}

resource "azurerm_virtual_network" "vnet" {
  name                = local.resolved.vnet_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = [local.resolved.vnet_cidr]
}

resource "azurerm_subnet" "aks" {
  name                 = local.resolved.subnet_name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [local.resolved.subnet_cidr]
  delegation {
    name = "aks-delegation"
    service_delegation {
      name = "Microsoft.ContainerService/managedClusters"
    }
  }
}
