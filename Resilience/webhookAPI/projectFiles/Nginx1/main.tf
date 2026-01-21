resource "proxmox_virtual_environment_vm" "ubuntu_vm" {
  count     = 1
  node_name = var.pve_node
  vm_id     = var.vm_id_start + count.index
  name      = "nginx1.auth"
  tags      = ["terraform" , "Resilience"]

  clone {
    vm_id = 9000
  }

  cpu {
    cores = 2
    type  = "host"
  }

  memory {
    dedicated = 512
  }

  network_device {
    bridge = "vmbr0"
  }

  initialization {
    datastore_id = "pveData"
    
    vendor_data_file_id = proxmox_virtual_environment_file.init_Nginx1.id

    user_account {
      username = var.vm_username
      password = var.vm_password
      keys     = [trimspace(file("/data/sshkeys/id_ed25519.pub"))]
    }

    ip_config {
      ipv4 {
        address = var.vm_ip_address
        gateway = var.vm_gateway
      }
    }

    dns {
      servers = var.vm_dns_servers
    }
  }
}