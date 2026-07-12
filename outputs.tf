# ============================================================
# PLG - 2026 / Groupe 24 : ESTIAM - Paris
# outputs.tf — Valeurs exposées après terraform apply
# ============================================================

# ----------------------------
# Load Balancer / Application
# ----------------------------
output "load_balancer_public_ip" {
  description = "IP publique du Load Balancer (point d'entrée web)"
  value       = module.loadbalancer.public_ip
}

output "web_url" {
  description = "URL publique de l'application web"
  value       = "http://${module.loadbalancer.public_ip}"
}

output "lb_health_probe_url" {
  description = "URL de la health probe du Load Balancer"
  value       = "http://${module.loadbalancer.public_ip}/health"
}

# ----------------------------
# Firewall
# ----------------------------
output "firewall_public_ip" {
  value = module.firewall.public_ip
}

output "firewall_private_ip" {
  value = module.firewall.private_ip
}

# ----------------------------
# VMs applicatives
# ----------------------------
output "vm_spoke1_private_ip" {
  value = module.vm_spoke1.private_ip
}

output "vm_spoke2_private_ip" {
  value = module.vm_spoke2.private_ip
}

# ----------------------------
# Supervision
# ----------------------------
output "monitoring_vm_private_ip" {
  description = "IP privée de la VM de supervision (Prometheus/Grafana)"
  value       = module.vm_monitoring.private_ip
}

output "grafana_url" {
  description = "URL Grafana (accessible depuis le CIDR défini par grafana_allowed_source)"
  value       = "http://${module.vm_monitoring.private_ip}:3000"
}

output "prometheus_url" {
  description = "URL Prometheus (accessible depuis le CIDR défini par grafana_allowed_source)"
  value       = "http://${module.vm_monitoring.private_ip}:9090"
}

# ----------------------------
# Bastion
# ----------------------------
output "bastion_name" {
  value = module.bastion.name
}

output "bastion_public_ip" {
  value = module.bastion.public_ip
}

# ----------------------------
# Réseau
# ----------------------------
output "hub_vnet_id" {
  value = module.network.hub_vnet_id
}

output "spoke1_vnet_id" {
  value = module.network.spoke1_vnet_id
}

output "spoke2_vnet_id" {
  value = module.network.spoke2_vnet_id
}

# ----------------------------
# Divers
# ----------------------------
output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "ping_test_vm1_to_vm2" {
  value = "ping ${module.vm_spoke2.private_ip}"
}

output "ping_test_vm2_to_vm1" {
  value = "ping ${module.vm_spoke1.private_ip}"
}
