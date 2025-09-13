output "vnet_name" {
  value = var.manage_vnet ? azurerm_virtual_network.vnet[0].name : data.azurerm_virtual_network.vnet[0].name
}

output "address_space" {
  value = var.manage_vnet ? azurerm_virtual_network.vnet[0].address_space : data.azurerm_virtual_network.vnet[0].address_space
}

output "subnets" {
  value = { for k, s in azurerm_subnet.subnets : k => { id = s.id, cidr = s.address_prefixes[0] } }
}
