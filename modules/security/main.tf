# ============================================================
# Module security — NSG générique + association au subnet
# ============================================================

resource "azurerm_network_security_group" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.rg_name
  tags                = var.tags

  dynamic "security_rule" {
    for_each = var.security_rules
    content {
      name                        = security_rule.value.name
      priority                    = security_rule.value.priority
      direction                   = security_rule.value.direction
      access                      = security_rule.value.access
      protocol                    = security_rule.value.protocol
      source_port_range           = security_rule.value.source_port_range
      destination_port_range      = try(security_rule.value.destination_port_range, null)
      destination_port_ranges     = try(security_rule.value.destination_port_ranges, null)
      source_address_prefix       = try(security_rule.value.source_address_prefix, null)
      source_address_prefixes     = try(security_rule.value.source_address_prefixes, null)
      destination_address_prefix  = security_rule.value.destination_address_prefix
    }
  }
}

resource "azurerm_subnet_network_security_group_association" "this" {
  subnet_id                 = var.subnet_id
  network_security_group_id = azurerm_network_security_group.this.id
}
