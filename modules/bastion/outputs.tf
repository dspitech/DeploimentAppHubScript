output "name" {
  value = azurerm_bastion_host.this.name
}

output "public_ip" {
  value = azurerm_public_ip.bastion_pip.ip_address
}
