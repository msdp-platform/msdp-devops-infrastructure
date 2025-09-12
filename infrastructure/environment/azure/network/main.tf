resource "azurerm_resource_group" "rg" {
  name     = local.az.resourceGroup
  location = local.global.azure.location
}

resource "azurerm_virtual_network" "vnet" {
  name                = local.az.vnetName
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = [coalesce(try(local.az.vnetCidr, null), local.global.azure.vnetCidrDefault)]
}

resource "azurerm_subnet" "aks" {
  name                 = local.az.subnetName
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [coalesce(try(local.az.subnetCidr, null), local.global.azure.subnetCidrDefault)]
  delegation {
    name = "aks-delegation"
    service_delegation { name = "Microsoft.ContainerService/managedClusters" }
  }
}
