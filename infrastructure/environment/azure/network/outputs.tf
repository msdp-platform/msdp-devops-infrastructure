# Azure Network Module Outputs

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_id" {
  description = "ID of the resource group"
  value       = azurerm_resource_group.main.id
}

output "vnet_name" {
  description = "Name of the virtual network"
  value       = azurerm_virtual_network.main.name
}

output "vnet_id" {
  description = "ID of the virtual network"
  value       = azurerm_virtual_network.main.id
}

output "vnet_address_space" {
  description = "Address space of the virtual network"
  value       = azurerm_virtual_network.main.address_space
}

output "subnets" {
  description = "Map of subnet names to their details"
  value = {
    for name, subnet in azurerm_subnet.subnets : name => {
      id               = subnet.id
      name             = subnet.name
      address_prefixes = subnet.address_prefixes
      cidr             = subnet.address_prefixes[0]
    }
  }
}

output "subnet_ids" {
  description = "Map of subnet names to their IDs"
  value = {
    for name, subnet in azurerm_subnet.subnets : name => subnet.id
  }
}

output "nsg_ids" {
  description = "Map of NSG names to their IDs"
  value = {
    for name, nsg in azurerm_network_security_group.subnets : name => nsg.id
  }
}