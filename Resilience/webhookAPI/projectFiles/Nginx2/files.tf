resource "proxmox_virtual_environment_file" "init_Nginx2" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = var.pve_node

  source_raw {
    data = templatefile("${path.module}/scripts/cloud-init-vendor.yaml.tpl", {
      init_b64 = base64encode(file("${path.module}/scripts/init.sh"))
      runningProject_b64 = base64encode(file("${path.module}/scripts/runningProject.sh"))
      nginx_conf_b64 = base64encode(file("${path.module}/scripts/nginx.conf"))
      auth_conf_b64 = base64encode(file("${path.module}/scripts/auth.conf"))
      keepalived_b64 = base64encode(file("${path.module}/scripts/keepalived.sh"))
      ssl_zip_b64 = filebase64("/opt/init/ssl.zip")
    })
    file_name = "init-Nginx2.yaml"
  }
}