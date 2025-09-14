locals {
  # Use the VNet resource group if specified, otherwise use the main resource group
  vnet_rg_name = coalesce(var.vnet_resource_group, var.resource_group)
}

# Conditional lookup - only if not managing network
data "azurerm_virtual_network" "vnet" {
  count               = var.manage_network ? 0 : 1
  name                = var.vnet_name
  resource_group_name = local.vnet_rg_name
}

# Conditional lookup - only if not managing network
data "azurerm_subnet" "aks_subnet" {
  count                = var.manage_network ? 0 : 1
  name                 = var.subnet_name
  virtual_network_name = var.vnet_name
  resource_group_name  = local.vnet_rg_name
}

locals {
  # Direct reference to the subnet ID from data source (when not managing)
  effective_subnet_id = var.manage_network ? "" : try(data.azurerm_subnet.aks_subnet[0].id, "")
  
  # Final subnet ID for use in main.tf
  final_subnet_id = local.effective_subnet_id
}
