output "subnet_id_aks" {
  description = "ID of the AKS subnet"
  value       = azurerm_subnet.aks.id
}

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.shared.name
}

output "vnet_name" {
  description = "Name of the virtual network"
  value       = azurerm_virtual_network.shared.name
}

output "subnet_name" {
  description = "Name of the AKS subnet"
  value       = azurerm_subnet.aks.name
}

output "vnet_id" {
  description = "ID of the virtual network"
  value       = azurerm_virtual_network.shared.id
}
