resource "proxmox_virtual_environment_file" "init_Nginx" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = var.pve_node

  source_raw {
    data = templatefile("${path.module}/scripts/cloud-init-vendor.yaml.tpl", {
      init_b64 = base64encode(file("${path.module}/scripts/init.sh"))
      runningProject_b64 = base64encode(file("${path.module}/scripts/runningProject.sh"))
      nginx_conf_b64 = base64encode(file("${path.module}/scripts/nginx.conf"))
      auth_conf_b64 = base64encode(file("${path.module}/scripts/auth.conf"))
    })
    file_name = "init-Nginx.yaml"
  }
}