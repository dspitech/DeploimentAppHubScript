# ============================================================
# Module network — VNets, Subnets, Peerings
# ============================================================

resource "azurerm_virtual_network" "hub" {
  name                = var.hub_vnet_name
  address_space       = var.hub_address_space
  location            = var.location
  resource_group_name = var.rg_name
  tags                = var.tags
}

resource "azurerm_virtual_network" "spoke1" {
  name                = var.spoke1_vnet_name
  address_space       = var.spoke1_address_space
  location            = var.location
  resource_group_name = var.rg_name
  tags                = var.tags
}

resource "azurerm_virtual_network" "spoke2" {
  name                = var.spoke2_vnet_name
  address_space       = var.spoke2_address_space
  location            = var.location
  resource_group_name = var.rg_name
  tags                = var.tags
}

# ----- Subnets Hub : services partagés -----
resource "azurerm_subnet" "firewall_subnet" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = var.rg_name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.subnet_firewall_prefix]
}

resource "azurerm_subnet" "bastion_subnet" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = var.rg_name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.subnet_bastion_prefix]
}

resource "azurerm_subnet" "hub_prod" {
  name                 = "Prod"
  resource_group_name  = var.rg_name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.subnet_hub_prod_prefix]
}

# ----- Subnets Hub : VMs applicatives -----
# NB : les VMs restent dans VnetHub pour respecter la contrainte du
# Load Balancer Standard (toutes les NIC doivent être dans le même VNet).
resource "azurerm_subnet" "hub_vm1" {
  name                 = "SubnetVM1"
  resource_group_name  = var.rg_name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.subnet_vm1_prefix]
}

resource "azurerm_subnet" "hub_vm2" {
  name                 = "SubnetVM2"
  resource_group_name  = var.rg_name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.subnet_vm2_prefix]
}

# ----- Subnet Hub : supervision (Prometheus/Grafana) -----
resource "azurerm_subnet" "hub_monitoring" {
  name                 = "SubnetMonitoring"
  resource_group_name  = var.rg_name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.subnet_monitoring_prefix]
}

# ----- Subnets Spokes -----
resource "azurerm_subnet" "spoke1_prod" {
  name                 = "Prod"
  resource_group_name  = var.rg_name
  virtual_network_name = azurerm_virtual_network.spoke1.name
  address_prefixes     = [var.spoke1_prod_prefix]
}

resource "azurerm_subnet" "spoke2_prod" {
  name                 = "Prod"
  resource_group_name  = var.rg_name
  virtual_network_name = azurerm_virtual_network.spoke2.name
  address_prefixes     = [var.spoke2_prod_prefix]
}

# ============================================================
# NAT Gateway — accès sortant Internet pour les VMs applicatives
# ------------------------------------------------------------
# INDISPENSABLE : les VM1/VM2 sont attachées au pool backend d'un
# Load Balancer Standard et n'ont pas d'IP publique propre. Un LB
# Standard ne fournit AUCUNE sortie Internet implicite (contrairement
# au SKU Basic) : sans NAT Gateway (ou règles outbound explicites sur
# le LB), apt-get / curl / git clone / npm install / Supabase échouent
# pendant le cloud-init, et l'application ne se déploie jamais.
# ============================================================
resource "azurerm_public_ip" "nat_pip" {
  name                = "IP-NatGateway-AppSubnets"
  location            = var.location
  resource_group_name = var.rg_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_nat_gateway" "app_subnets" {
  name                    = "NatGateway-AppSubnets"
  location                = var.location
  resource_group_name     = var.rg_name
  sku_name                = "Standard"
  idle_timeout_in_minutes = 10
  tags                    = var.tags
}

resource "azurerm_nat_gateway_public_ip_association" "app_subnets" {
  nat_gateway_id       = azurerm_nat_gateway.app_subnets.id
  public_ip_address_id = azurerm_public_ip.nat_pip.id
}

resource "azurerm_subnet_nat_gateway_association" "vm1" {
  subnet_id      = azurerm_subnet.hub_vm1.id
  nat_gateway_id = azurerm_nat_gateway.app_subnets.id
}

resource "azurerm_subnet_nat_gateway_association" "vm2" {
  subnet_id      = azurerm_subnet.hub_vm2.id
  nat_gateway_id = azurerm_nat_gateway.app_subnets.id
}

# ----- Peerings Hub <-> Spokes -----
resource "azurerm_virtual_network_peering" "hub_to_spoke1" {
  name                         = "HubToSpoke1"
  resource_group_name          = var.rg_name
  virtual_network_name         = azurerm_virtual_network.hub.name
  remote_virtual_network_id    = azurerm_virtual_network.spoke1.id
  allow_forwarded_traffic      = true
  allow_virtual_network_access = true
}

resource "azurerm_virtual_network_peering" "spoke1_to_hub" {
  name                         = "Spoke1ToHub"
  resource_group_name          = var.rg_name
  virtual_network_name         = azurerm_virtual_network.spoke1.name
  remote_virtual_network_id    = azurerm_virtual_network.hub.id
  allow_forwarded_traffic      = true
  allow_virtual_network_access = true
}

resource "azurerm_virtual_network_peering" "hub_to_spoke2" {
  name                         = "HubToSpoke2"
  resource_group_name          = var.rg_name
  virtual_network_name         = azurerm_virtual_network.hub.name
  remote_virtual_network_id    = azurerm_virtual_network.spoke2.id
  allow_forwarded_traffic      = true
  allow_virtual_network_access = true
}

resource "azurerm_virtual_network_peering" "spoke2_to_hub" {
  name                         = "Spoke2ToHub"
  resource_group_name          = var.rg_name
  virtual_network_name         = azurerm_virtual_network.spoke2.name
  remote_virtual_network_id    = azurerm_virtual_network.hub.id
  allow_forwarded_traffic      = true
  allow_virtual_network_access = true
}
