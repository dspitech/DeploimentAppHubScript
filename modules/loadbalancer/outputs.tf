output "public_ip" {
  value = azurerm_public_ip.lb_pip.ip_address
}

output "backend_pool_id" {
  value = azurerm_lb_backend_address_pool.backend_pool.id
}
