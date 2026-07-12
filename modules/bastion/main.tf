# ============================================================
# Module bastion — Azure Bastion (accès SSH/RDP sécurisé, sans IP publique sur les VMs)
# ============================================================

resource "azurerm_public_ip" "bastion_pip" {
  name                = "IP-Bastion"
  location            = var.location
  resource_group_name = var.rg_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_bastion_host" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.rg_name
  tags                = var.tags

  ip_configuration {
    name                 = "Bastion-Config"
    subnet_id            = var.bastion_subnet_id
    public_ip_address_id = azurerm_public_ip.bastion_pip.id
  }
}
