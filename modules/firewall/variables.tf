variable "name" {
  type = string
}

variable "location" {
  type = string
}

variable "rg_name" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "firewall_subnet_id" {
  type = string
}

variable "spoke1_prod_prefix" {
  type = string
}

variable "spoke2_prod_prefix" {
  type = string
}

variable "spoke1_prod_subnet_id" {
  type = string
}

variable "spoke2_prod_subnet_id" {
  type = string
}
