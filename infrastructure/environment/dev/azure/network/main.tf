# Resource Group
resource "azurerm_resource_group" "shared" {
  name     = local.resolved.resource_group
  location = local.resolved.location

  tags = {
    Environment = var.env
    ManagedBy   = "Terraform"
    Component   = "Network"
  }
}

# Virtual Network
resource "azurerm_virtual_network" "shared" {
  name                = local.resolved.vnet_name
  address_space       = [local.resolved.vnet_cidr]
  location            = azurerm_resource_group.shared.location
  resource_group_name = azurerm_resource_group.shared.name

  tags = {
    Environment = var.env
    ManagedBy   = "Terraform"
    Component   = "Network"
  }
}

# Subnet for AKS
resource "azurerm_subnet" "aks" {
  name                 = local.resolved.subnet_name
  resource_group_name  = azurerm_resource_group.shared.name
  virtual_network_name = azurerm_virtual_network.shared.name
  address_prefixes     = [local.resolved.subnet_cidr]
}
