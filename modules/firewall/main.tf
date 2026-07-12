# ============================================================
# Module firewall — Azure Firewall + règles + tables de routage
# ============================================================

resource "azurerm_public_ip" "fw_pip" {
  name                = "IP-${var.name}"
  location            = var.location
  resource_group_name = var.rg_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_firewall" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.rg_name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"
  tags                = var.tags

  ip_configuration {
    name                 = "FW-Config"
    subnet_id            = var.firewall_subnet_id
    public_ip_address_id = azurerm_public_ip.fw_pip.id
  }
}

resource "azurerm_firewall_network_rule_collection" "inter_spoke" {
  name                = "Allow-InterSpoke"
  azure_firewall_name = azurerm_firewall.this.name
  resource_group_name = var.rg_name
  priority            = 100
  action              = "Allow"

  rule {
    name                  = "Spoke1-to-Spoke2-Ping"
    protocols             = ["ICMP"]
    source_addresses      = [var.spoke1_prod_prefix]
    destination_addresses = [var.spoke2_prod_prefix]
    destination_ports     = ["*"]
  }

  rule {
    name                  = "Spoke2-to-Spoke1-Ping"
    protocols             = ["ICMP"]
    source_addresses      = [var.spoke2_prod_prefix]
    destination_addresses = [var.spoke1_prod_prefix]
    destination_ports     = ["*"]
  }
}

# ----- Tables de routage (UDR) : forcent le trafic inter-spoke via le firewall -----
resource "azurerm_route_table" "udr_spoke1" {
  name                = "UdrSpoke1"
  location            = var.location
  resource_group_name = var.rg_name
  tags                = var.tags

  route {
    name                   = "To-Spoke2"
    address_prefix         = var.spoke2_prod_prefix
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.this.ip_configuration[0].private_ip_address
  }
}

resource "azurerm_route_table" "udr_spoke2" {
  name                = "UdrSpoke2"
  location            = var.location
  resource_group_name = var.rg_name
  tags                = var.tags

  route {
    name                   = "To-Spoke1"
    address_prefix         = var.spoke1_prod_prefix
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.this.ip_configuration[0].private_ip_address
  }
}

resource "azurerm_subnet_route_table_association" "udr_spoke1_assoc" {
  subnet_id      = var.spoke1_prod_subnet_id
  route_table_id = azurerm_route_table.udr_spoke1.id
}

resource "azurerm_subnet_route_table_association" "udr_spoke2_assoc" {
  subnet_id      = var.spoke2_prod_subnet_id
  route_table_id = azurerm_route_table.udr_spoke2.id
}
