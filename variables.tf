# ============================================================
# PLG - 2026 / Groupe 24 : ESTIAM - Paris
# variables.tf — Déclarations des variables du module racine
# ============================================================

# ----------------------------
# Général
# ----------------------------
variable "rg_name" {
  description = "Nom du Resource Group Azure"
  type        = string
  default     = "RG-PLG-ESTIAM-Paris-2026"
}

variable "location" {
  description = "Région Azure cible"
  type        = string
  default     = "norwayeast"
}

variable "tags" {
  description = "Tags appliqués à toutes les ressources"
  type        = map(string)
  default = {
    Project     = "Deployment-Script-Tools"
    Environment = "Production"
    ManagedBy   = "Terraform"
    Author      = "PLG-Groupe24-ESTIAM-2026"
  }
}

# ----------------------------
# Authentification VMs
# ----------------------------
variable "admin_username" {
  description = "Nom du compte administrateur sur les VMs Linux"
  type        = string
  default     = "scripttools_plgEstiam"
}

variable "ssh_public_key_path" {
  description = "Chemin vers la clé publique SSH pour les VMs"
  type        = string
  default     = "~/clouddrive/hubspoke_rsa.pub"
}

# ----------------------------
# Réseau - VNets
# ----------------------------
variable "hub_vnet_name" {
  type    = string
  default = "VnetHub"
}

variable "hub_address_space" {
  type    = list(string)
  default = ["10.0.0.0/16"]
}

variable "spoke1_vnet_name" {
  type    = string
  default = "VnetSpoke1"
}

variable "spoke1_address_space" {
  type    = list(string)
  default = ["192.168.0.0/24"]
}

variable "spoke2_vnet_name" {
  type    = string
  default = "VnetSpoke2"
}

variable "spoke2_address_space" {
  type    = list(string)
  default = ["172.16.0.0/24"]
}

# ----------------------------
# Réseau - Subnets Hub
# ----------------------------
variable "subnet_firewall_prefix" {
  type    = string
  default = "10.0.2.0/24"
}

variable "subnet_bastion_prefix" {
  type    = string
  default = "10.0.4.0/24"
}

variable "subnet_hub_prod_prefix" {
  type    = string
  default = "10.0.1.0/24"
}

variable "subnet_vm1_prefix" {
  type    = string
  default = "10.0.10.0/24"
}

variable "subnet_vm2_prefix" {
  type    = string
  default = "10.0.11.0/24"
}

variable "subnet_monitoring_prefix" {
  description = "CIDR du subnet hébergeant la VM de supervision (Prometheus/Grafana)"
  type        = string
  default     = "10.0.12.0/24"
}

# ----------------------------
# Réseau - Subnets Spokes
# ----------------------------
variable "spoke1_prod_prefix" {
  type    = string
  default = "192.168.0.0/24"
}

variable "spoke2_prod_prefix" {
  type    = string
  default = "172.16.0.0/24"
}

# ----------------------------
# Machines Virtuelles applicatives
# ----------------------------
variable "vm_size" {
  type    = string
  default = "Standard_B2s"
}

variable "vm_image" {
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
  default = {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}

# ----------------------------
# VM de supervision (Prometheus/Grafana)
# ----------------------------
variable "monitoring_vm_size" {
  description = "Taille de la VM de supervision (peut rester modeste)"
  type        = string
  default     = "Standard_B2s"
}

variable "node_exporter_version" {
  description = "Version de node_exporter à installer sur les noeuds applicatifs"
  type        = string
  default     = "1.8.2"
}

variable "grafana_admin_user" {
  description = "Utilisateur admin Grafana"
  type        = string
  default     = "admin"
}

variable "grafana_admin_password" {
  description = "Mot de passe admin Grafana (à définir via TF_VAR_grafana_admin_password ou terraform.tfvars non commité)"
  type        = string
  sensitive   = true
}

variable "grafana_allowed_source" {
  description = "Préfixe CIDR autorisé à accéder à Grafana (3000) et Prometheus (9090) depuis l'extérieur du VNet. Par défaut, accès restreint au VNet ; ajoutez votre IP publique en /32 si besoin d'un accès direct."
  type        = string
  default     = "10.0.0.0/16"
}

# ----------------------------
# Load Balancer
# ----------------------------
variable "lb_name" {
  type    = string
  default = "LB-HUB-SPOKE"
}

variable "lb_probe_interval" {
  type    = number
  default = 15
}

variable "lb_probe_count" {
  type    = number
  default = 2
}

# ----------------------------
# Firewall
# ----------------------------
variable "firewall_name" {
  type    = string
  default = "AzureFireWall"
}

# ----------------------------
# Application / GitHub / Supabase
# ----------------------------
variable "github_repo_url" {
  description = "URL HTTPS du dépôt GitHub de l'application"
  type        = string
  default     = "https://github.com/dspitech/plg-projet-pedagogique-2026-groupe-24.git"
}

variable "repo_name" {
  description = "Nom du dossier local du dépôt cloné"
  type        = string
  default     = "plg-projet-pedagogique-2026-groupe-24"
}

variable "supabase_url" {
  description = "URL du projet Supabase"
  type        = string
}

variable "supabase_anon_key" {
  description = "Clé publique (anon) Supabase"
  type        = string
  sensitive   = true
}

variable "database_url" {
  description = "Chaîne de connexion PostgreSQL Supabase (postgresql://...)"
  type        = string
  sensitive   = true
}

# ----------------------------
# CI/CD — GitHub Actions self-hosted runner
# Les VMs n'ayant pas d'IP publique SSH exposée (accès uniquement via Bastion),
# le déploiement continu se fait via un runner auto-hébergé qui va chercher
# le travail sur GitHub (aucun port entrant à ouvrir).
# ----------------------------
variable "github_owner" {
  description = "Propriétaire (org ou user) du dépôt GitHub"
  type        = string
  default     = "dspitech"
}

variable "github_pat" {
  description = "GitHub Personal Access Token (scope 'repo' + 'workflow') utilisé uniquement au démarrage de la VM pour enregistrer le runner auto-hébergé. Fournir via TF_VAR_github_pat, jamais en dur dans un fichier commité."
  type        = string
  sensitive   = true
}

variable "runner_version" {
  description = "Version du GitHub Actions runner à installer"
  type        = string
  default     = "2.319.1"
}
