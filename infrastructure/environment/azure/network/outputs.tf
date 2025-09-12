output "vnet_name" {
  value = azurerm_virtual_network.vnet.name
}

output "address_space" {
  value = azurerm_virtual_network.vnet.address_space
}

output "subnets" {
  value = { for k, s in azurerm_subnet.subnets : k => { id = s.id, cidr = s.address_prefixes[0] } }
}
