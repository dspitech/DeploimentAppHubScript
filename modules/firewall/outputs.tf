output "public_ip" {
  value = azurerm_public_ip.fw_pip.ip_address
}

output "private_ip" {
  value = azurerm_firewall.this.ip_configuration[0].private_ip_address
}

output "firewall_name" {
  value = azurerm_firewall.this.name
}
