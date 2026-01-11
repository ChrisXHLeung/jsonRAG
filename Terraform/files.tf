resource "proxmox_virtual_environment_file" "init_vendor" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = var.pve_node

  source_raw {
    data = templatefile("${path.module}/scripts/cloud-init-vendor.yaml.tpl", {
      init_b64 = base64encode(file("${path.module}/scripts/init.sh"))
      install_docker_b64 = base64encode(file("${path.module}/scripts/install-docker.sh"))
      envFile_b64 = base64encode(file("${path.module}/projectResource/.env"))
      runningProject_b64 = base64encode(file("${path.module}/scripts/runningProject.sh"))
    })
    file_name = "vendor-init.yaml"
  }
}