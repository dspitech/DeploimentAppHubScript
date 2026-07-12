variable "name" {
  type    = string
  default = "AzureBastion"
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

variable "bastion_subnet_id" {
  type = string
}
