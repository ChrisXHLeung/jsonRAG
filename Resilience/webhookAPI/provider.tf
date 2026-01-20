terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.93.0"
    }
  }
}

provider "proxmox" {
  endpoint  = var.pve_api_url
  api_token = "${var.pve_token_id}=${var.pve_token_secret}"
  insecure  = true

  ssh {
    username = var.pve_ssh_username
    password = var.pve_ssh_password
    agent    = false

    node {
      name    = var.pve_node
      address = var.pve_ssh_node_address
    }
  }
}