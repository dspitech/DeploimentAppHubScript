# ============================================================
# Module loadbalancer — Azure Load Balancer Standard (HTTP/HTTPS)
# ============================================================

resource "azurerm_public_ip" "lb_pip" {
  name                = "IP-LoadBalancer"
  location            = var.location
  resource_group_name = var.rg_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_lb" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.rg_name
  sku                 = "Standard"
  tags                = var.tags

  frontend_ip_configuration {
    name                 = "FrontEnd"
    public_ip_address_id = azurerm_public_ip.lb_pip.id
  }
}

resource "azurerm_lb_backend_address_pool" "backend_pool" {
  name            = "BackEndPool"
  loadbalancer_id = azurerm_lb.this.id
}

resource "azurerm_lb_probe" "http_probe" {
  name                = "HttpProbe"
  loadbalancer_id     = azurerm_lb.this.id
  protocol            = "Http"
  port                = 80
  request_path        = "/health"
  interval_in_seconds = var.probe_interval
  number_of_probes    = var.probe_count
}

resource "azurerm_lb_rule" "lb_rule_http" {
  name                           = "LBRuleHTTP"
  loadbalancer_id                = azurerm_lb.this.id
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "FrontEnd"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.backend_pool.id]
  probe_id                       = azurerm_lb_probe.http_probe.id
  enable_floating_ip             = false
  idle_timeout_in_minutes        = 4
}

resource "azurerm_lb_rule" "lb_rule_https" {
  name                           = "LBRuleHTTPS"
  loadbalancer_id                = azurerm_lb.this.id
  protocol                       = "Tcp"
  frontend_port                  = 443
  backend_port                   = 443
  frontend_ip_configuration_name = "FrontEnd"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.backend_pool.id]
  probe_id                       = azurerm_lb_probe.http_probe.id
  enable_floating_ip             = false
  idle_timeout_in_minutes        = 4
}

# ============================================================
# Règle outbound — accès sortant Internet pour les VM1/VM2
# ------------------------------------------------------------
# Un Load Balancer Standard ne fournit AUCUNE sortie Internet implicite
# aux VMs de son backend pool (contrairement au SKU Basic). Sans cette
# règle (ou une NAT Gateway dédiée), apt-get / curl / git clone / npm
# install / Supabase échoueraient pendant le cloud-init des VM1/VM2.
# On réutilise ici l'IP publique déjà créée pour le LB (frontend HTTP/S)
# plutôt qu'une NAT Gateway séparée, pour rester dans le quota de 3 IP
# publiques de la subscription.
# ============================================================
resource "azurerm_lb_outbound_rule" "app_outbound" {
  name                    = "OutboundToInternet"
  loadbalancer_id         = azurerm_lb.this.id
  protocol                = "All"
  backend_address_pool_id = azurerm_lb_backend_address_pool.backend_pool.id
  allocated_outbound_ports = 10000
  idle_timeout_in_minutes  = 4

  frontend_ip_configuration {
    name = "FrontEnd"
  }
}
