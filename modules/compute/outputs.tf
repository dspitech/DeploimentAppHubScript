output "private_ip" {
  value = azurerm_network_interface.this.private_ip_address
}

output "vm_id" {
  value = azurerm_linux_virtual_machine.this.id
}

output "vm_name" {
  value = azurerm_linux_virtual_machine.this.name
}

output "public_ip" {
  description = "IP publique de la VM (null si enable_public_ip = false)"
  value       = var.enable_public_ip ? azurerm_public_ip.this[0].ip_address : null
}
