# ============================================================
# PLG - 2026 / Groupe 24 : ESTIAM - Paris
# main.tf — Orchestration des modules (réseau, sécurité, compute, supervision)
# ============================================================

resource "azurerm_resource_group" "rg" {
  name     = var.rg_name
  location = var.location
  tags     = var.tags
}

# ============================================================
# Réseau
# ============================================================
module "network" {
  source = "./modules/network"

  rg_name              = azurerm_resource_group.rg.name
  location             = azurerm_resource_group.rg.location
  tags                 = var.tags

  hub_vnet_name            = var.hub_vnet_name
  hub_address_space        = var.hub_address_space
  spoke1_vnet_name         = var.spoke1_vnet_name
  spoke1_address_space     = var.spoke1_address_space
  spoke2_vnet_name         = var.spoke2_vnet_name
  spoke2_address_space     = var.spoke2_address_space

  subnet_firewall_prefix   = var.subnet_firewall_prefix
  subnet_bastion_prefix    = var.subnet_bastion_prefix
  subnet_hub_prod_prefix   = var.subnet_hub_prod_prefix
  subnet_vm1_prefix        = var.subnet_vm1_prefix
  subnet_vm2_prefix        = var.subnet_vm2_prefix
  subnet_monitoring_prefix = var.subnet_monitoring_prefix

  spoke1_prod_prefix = var.spoke1_prod_prefix
  spoke2_prod_prefix = var.spoke2_prod_prefix
}

# ============================================================
# Firewall — RETIRÉ
# ------------------------------------------------------------
# Le firewall ne routait que le trafic inter-spoke (ICMP Spoke1<->Spoke2),
# or les VM1/VM2 sont en réalité hébergées dans VnetHub (SubnetVM1/SubnetVM2,
# contrainte du Load Balancer Standard) et non dans les VNets Spoke1/Spoke2.
# Les routes UDR ciblaient donc des subnets Spoke vides, sans VM dessus :
# ce module ne servait à rien fonctionnellement, tout en consommant une
# IP publique. Retiré pour respecter le quota de 3 IP publiques de la
# subscription (LB + Bastion + VM-MONITORING).
# Le code du module reste disponible dans modules/firewall/ si vous
# voulez le réactiver plus tard (ex : upgrade de quota, ou VMs réellement
# déplacées dans les VNets Spoke).
# ============================================================

# ============================================================
# Bastion (accès admin sécurisé, sans IP publique sur les VMs)
# ============================================================
module "bastion" {
  source = "./modules/bastion"

  location          = azurerm_resource_group.rg.location
  rg_name           = azurerm_resource_group.rg.name
  tags              = var.tags
  bastion_subnet_id = module.network.bastion_subnet_id
}

# ============================================================
# Load Balancer Standard
# ============================================================
module "loadbalancer" {
  source = "./modules/loadbalancer"

  name           = var.lb_name
  location       = azurerm_resource_group.rg.location
  rg_name        = azurerm_resource_group.rg.name
  tags           = var.tags
  probe_interval = var.lb_probe_interval
  probe_count    = var.lb_probe_count
}

# ============================================================
# NSG — Noeuds applicatifs (SubnetVM1 / SubnetVM2)
# Durci par rapport à la version initiale : plus de "*" en source,
# les ports de debug (3000/3001/5432/8080/8443/54321) ne sont plus
# exposés publiquement (Nginx sert déjà le tout sur 80/443).
# ============================================================
locals {
  app_nsg_rules = [
    {
      name                       = "Allow-SSH-From-Bastion"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "22"
      source_address_prefix      = var.subnet_bastion_prefix
      destination_address_prefix = "*"
    },
    {
      name                       = "Allow-HTTP-Internet"
      priority                   = 110
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "80"
      source_address_prefix      = "Internet"
      destination_address_prefix = "*"
    },
    {
      name                       = "Allow-HTTPS-Internet"
      priority                   = 120
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "Internet"
      destination_address_prefix = "*"
    },
    {
      name                       = "Allow-NodeExporter-From-Monitoring"
      priority                   = 130
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "9100"
      source_address_prefix      = var.subnet_monitoring_prefix
      destination_address_prefix = "*"
    },
    {
      name                       = "Allow-Ping-Internal"
      priority                   = 200
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Icmp"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "*"
    },
    {
      # CRITIQUE : autorise les health probes du Load Balancer Standard
      name                       = "Allow-AzureLoadBalancer"
      priority                   = 210
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "AzureLoadBalancer"
      destination_address_prefix = "*"
    },
  ]
}

module "nsg_vm1" {
  source = "./modules/security"

  name           = "NSG-VM1"
  location       = azurerm_resource_group.rg.location
  rg_name        = azurerm_resource_group.rg.name
  tags           = var.tags
  subnet_id      = module.network.vm1_subnet_id
  security_rules = local.app_nsg_rules
}

module "nsg_vm2" {
  source = "./modules/security"

  name           = "NSG-VM2"
  location       = azurerm_resource_group.rg.location
  rg_name        = azurerm_resource_group.rg.name
  tags           = var.tags
  subnet_id      = module.network.vm2_subnet_id
  security_rules = local.app_nsg_rules
}

# ============================================================
# NSG — Noeud de supervision (Prometheus/Grafana)
# ============================================================
module "nsg_monitoring" {
  source = "./modules/security"

  name      = "NSG-Monitoring"
  location  = azurerm_resource_group.rg.location
  rg_name   = azurerm_resource_group.rg.name
  tags      = var.tags
  subnet_id = module.network.monitoring_subnet_id

  security_rules = [
    {
      name                       = "Allow-SSH-From-Bastion"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "22"
      source_address_prefix      = var.subnet_bastion_prefix
      destination_address_prefix = "*"
    },
    {
      name                       = "Allow-Grafana"
      priority                   = 110
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "3000"
      source_address_prefix      = var.grafana_allowed_source
      destination_address_prefix = "*"
    },
    {
      name                       = "Allow-Prometheus"
      priority                   = 120
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "9090"
      source_address_prefix      = var.grafana_allowed_source
      destination_address_prefix = "*"
    },
  ]
}

# ============================================================
# Cloud-init — noeuds applicatifs (un runner GitHub Actions distinct par VM)
# ============================================================
locals {
  app_cloud_init_common = {
    admin_username        = var.admin_username
    github_repo_url       = var.github_repo_url
    repo_name             = var.repo_name
    supabase_url          = var.supabase_url
    supabase_anon_key     = var.supabase_anon_key
    database_url          = var.database_url
    node_exporter_version = var.node_exporter_version
    github_owner          = var.github_owner
    github_pat            = var.github_pat
    runner_version        = var.runner_version
  }

  app_cloud_init_vm1 = templatefile("${path.module}/cloud-init/app-node.yaml.tpl", merge(
    local.app_cloud_init_common, { runner_label = "vm-spoke-1" }
  ))

  app_cloud_init_vm2 = templatefile("${path.module}/cloud-init/app-node.yaml.tpl", merge(
    local.app_cloud_init_common, { runner_label = "vm-spoke-2" }
  ))
}

# ============================================================
# VM applicative 1
# ============================================================
module "vm_spoke1" {
  source = "./modules/compute"

  vm_name             = "VM-SPOKE-1"
  location            = azurerm_resource_group.rg.location
  rg_name             = azurerm_resource_group.rg.name
  tags                = var.tags
  subnet_id           = module.network.vm1_subnet_id
  vm_size             = var.vm_size
  admin_username      = var.admin_username
  ssh_public_key_path = var.ssh_public_key_path
  vm_image            = var.vm_image
  custom_data_base64  = base64encode(local.app_cloud_init_vm1)
  attach_to_lb        = true
  backend_pool_id     = module.loadbalancer.backend_pool_id
}

# ============================================================
# VM applicative 2
# ============================================================
module "vm_spoke2" {
  source = "./modules/compute"

  vm_name             = "VM-SPOKE-2"
  location            = azurerm_resource_group.rg.location
  rg_name             = azurerm_resource_group.rg.name
  tags                = var.tags
  subnet_id           = module.network.vm2_subnet_id
  vm_size             = var.vm_size
  admin_username      = var.admin_username
  ssh_public_key_path = var.ssh_public_key_path
  vm_image            = var.vm_image
  custom_data_base64  = base64encode(local.app_cloud_init_vm2)
  attach_to_lb        = true
  backend_pool_id     = module.loadbalancer.backend_pool_id
}

# ============================================================
# Cloud-init — noeud de supervision (Prometheus + Grafana)
# ============================================================
locals {
  monitoring_cloud_init = templatefile("${path.module}/cloud-init/monitoring-node.yaml.tpl", {
    grafana_admin_user     = var.grafana_admin_user
    grafana_admin_password = var.grafana_admin_password
    vm1_ip                 = module.vm_spoke1.private_ip
    vm2_ip                 = module.vm_spoke2.private_ip
  })
}

# ============================================================
# VM de supervision — Prometheus + Grafana (dashboard auto-provisionné)
# ============================================================
module "vm_monitoring" {
  source = "./modules/compute"

  vm_name             = "VM-MONITORING"
  location            = azurerm_resource_group.rg.location
  rg_name             = azurerm_resource_group.rg.name
  tags                = var.tags
  subnet_id           = module.network.monitoring_subnet_id
  vm_size             = var.monitoring_vm_size
  admin_username      = var.admin_username
  ssh_public_key_path = var.ssh_public_key_path
  vm_image            = var.vm_image
  custom_data_base64  = base64encode(local.monitoring_cloud_init)

  # IP publique dédiée : indispensable pour accéder à Grafana/Prometheus
  # directement depuis Internet (voir grafana_allowed_source ci-dessous
  # pour restreindre QUI peut s'y connecter).
  enable_public_ip = true
}
