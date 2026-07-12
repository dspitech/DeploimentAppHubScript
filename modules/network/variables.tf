variable "rg_name" {
  description = "Nom du Resource Group"
  type        = string
}

variable "location" {
  description = "Région Azure"
  type        = string
}

variable "tags" {
  description = "Tags communs"
  type        = map(string)
}

variable "hub_vnet_name" {
  type = string
}

variable "hub_address_space" {
  type = list(string)
}

variable "spoke1_vnet_name" {
  type = string
}

variable "spoke1_address_space" {
  type = list(string)
}

variable "spoke2_vnet_name" {
  type = string
}

variable "spoke2_address_space" {
  type = list(string)
}

variable "subnet_firewall_prefix" {
  type = string
}

variable "subnet_bastion_prefix" {
  type = string
}

variable "subnet_hub_prod_prefix" {
  type = string
}

variable "subnet_vm1_prefix" {
  type = string
}

variable "subnet_vm2_prefix" {
  type = string
}

variable "subnet_monitoring_prefix" {
  description = "CIDR du subnet hébergeant la VM de supervision (Prometheus/Grafana)"
  type        = string
}

variable "spoke1_prod_prefix" {
  type = string
}

variable "spoke2_prod_prefix" {
  type = string
}
