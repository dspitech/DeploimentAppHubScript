output "hub_vnet_id" {
  value = azurerm_virtual_network.hub.id
}

output "hub_vnet_name" {
  value = azurerm_virtual_network.hub.name
}

output "spoke1_vnet_id" {
  value = azurerm_virtual_network.spoke1.id
}

output "spoke2_vnet_id" {
  value = azurerm_virtual_network.spoke2.id
}

output "firewall_subnet_id" {
  value = azurerm_subnet.firewall_subnet.id
}

output "bastion_subnet_id" {
  value = azurerm_subnet.bastion_subnet.id
}

output "hub_prod_subnet_id" {
  value = azurerm_subnet.hub_prod.id
}

output "vm1_subnet_id" {
  value = azurerm_subnet.hub_vm1.id
}

output "vm2_subnet_id" {
  value = azurerm_subnet.hub_vm2.id
}

output "monitoring_subnet_id" {
  value = azurerm_subnet.hub_monitoring.id
}

output "spoke1_prod_subnet_id" {
  value = azurerm_subnet.spoke1_prod.id
}

output "spoke2_prod_subnet_id" {
  value = azurerm_subnet.spoke2_prod.id
}

output "nat_gateway_public_ip" {
  description = "IP publique utilisée par les VM1/VM2 pour sortir vers Internet (NAT Gateway)"
  value       = azurerm_public_ip.nat_pip.ip_address
}
