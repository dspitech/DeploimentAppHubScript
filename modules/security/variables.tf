variable "name" {
  description = "Nom du NSG"
  type        = string
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

variable "subnet_id" {
  description = "Subnet auquel associer ce NSG"
  type        = string
}

variable "security_rules" {
  description = "Liste des règles de sécurité du NSG"
  type = list(object({
    name                       = string
    priority                   = number
    direction                  = string
    access                     = string
    protocol                   = string
    source_port_range          = string
    destination_port_range    = optional(string)
    destination_port_ranges   = optional(list(string))
    source_address_prefix     = optional(string)
    source_address_prefixes   = optional(list(string))
    destination_address_prefix = string
  }))
  default = []
}
