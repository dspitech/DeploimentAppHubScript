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

variable "probe_interval" {
  type    = number
  default = 15
}

variable "probe_count" {
  type    = number
  default = 2
}
