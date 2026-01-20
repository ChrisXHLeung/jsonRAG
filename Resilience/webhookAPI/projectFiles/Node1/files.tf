resource "proxmox_virtual_environment_file" "init_Node1" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = var.pve_node

  source_raw {
    data = templatefile("${path.module}/scripts/cloud-init-vendor.yaml.tpl", {
      init_b64 = base64encode(file("${path.module}/scripts/init.sh"))
      install_docker_b64 = base64encode(file("${path.module}/scripts/install-docker.sh"))
      envFile_b64 = base64encode(file("${path.module}/projectResource/.env"))
      runningProject_b64 = base64encode(file("${path.module}/scripts/runningProject.sh"))
      cerbos_audit_b64 = base64encode(file("${path.module}/scripts/cerbos.audit.conf"))
      cerbos_audit_stats_b64 = base64encode(file("${path.module}/scripts/cerbos_audit_stats.sh"))
      mount_object_b64 = base64encode(file("${path.module}/scripts/mount-object.sh"))
    })
    file_name = "init-Node1.yaml"
  }
}