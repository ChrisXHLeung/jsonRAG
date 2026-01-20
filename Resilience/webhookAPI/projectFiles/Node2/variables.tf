variable "pve_api_url" {
  type = string
}

variable "pve_token_id" {
  type = string
}

variable "pve_token_secret" {
  type      = string
  sensitive = true
}

variable "pve_node" {
  type    = string
  default = "pve"
}

variable "vm_id_start" {
  type    = number
  default = 20001
}

variable "vm_ip_address" {
  type    = string
  default = ""
}

variable "vm_gateway" {
  type    = string
  default = ""
}

variable "vm_dns_servers" {
  type    = list(string)
  default = []
}

variable "vm_username" {
  type    = string
  default = ""
}

variable "vm_password" {
  type      = string
  sensitive = true
  default   = ""
}

variable "pve_ssh_username" {
  type    = string
  default = ""
}

variable "pve_ssh_password" {
  type      = string
  sensitive = true
  default   = ""
}

variable "pve_ssh_node_address" {
  type    = string
  default = ""
}

variable "oci_par_url" {
  type = string
}

variable "oci_par_name" {
  type    = string
  default = "oci-par"
}