output "vnet_name" {
  value = coalesce(try(azurerm_virtual_network.vnet[0].name, null), try(data.azurerm_virtual_network.vnet[0].name, null))
}

output "address_space" {
  value = coalesce(try(azurerm_virtual_network.vnet[0].address_space, null), try(data.azurerm_virtual_network.vnet[0].address_space, null))
}

output "subnets" {
  value = { for k, s in azurerm_subnet.subnets : k => { id = s.id, cidr = s.address_prefixes[0] } }
}
