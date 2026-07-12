variable "vm_name" {
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

variable "subnet_id" {
  type = string
}

variable "vm_size" {
  type = string
}

variable "admin_username" {
  type = string
}

variable "ssh_public_key_path" {
  type = string
}

variable "vm_image" {
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
}

variable "custom_data_base64" {
  description = "cloud-init déjà encodé en base64"
  type        = string
}

variable "os_disk_type" {
  type    = string
  default = "Premium_LRS"
}

variable "os_disk_size_gb" {
  type    = number
  default = null
}

variable "backend_pool_id" {
  description = "ID du backend pool du Load Balancer à associer (optionnel)"
  type        = string
  default     = null
}

variable "attach_to_lb" {
  description = "Doit être true/false littéral (connu au plan) : indique si cette VM doit être attachée au backend pool du Load Balancer. Ne PAS déduire cette valeur de backend_pool_id != null, car l'ID d'un backend pool nouvellement créé n'est connu qu'après apply, ce qui ferait échouer 'count' au moment du plan."
  type        = bool
  default     = false
}

variable "private_ip_address" {
  description = "IP privée statique (optionnel, sinon Dynamic)"
  type        = string
  default     = null
}
