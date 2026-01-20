resource "proxmox_virtual_environment_file" "init_Webhook" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = var.pve_node

  source_raw {
    data = templatefile("${path.module}/scripts/cloud-init-vendor.yaml.tpl", {
      init_b64 = base64encode(file("${path.module}/scripts/init.sh"))
      terraformDeploy_b64 = base64encode(file("${path.module}/scripts/terraformDeploy.sh"))
      webhookDeploy_b64 = base64encode(file("${path.module}/scripts/webhookDeploy.sh"))
      main_py_b64 = base64encode(file("${path.module}/projectFiles/main.py"))
      jsonRAGRebuild1_b64 = base64encode(file("${path.module}/scripts/jsonRAGReBuild1.sh"))
      jsonRAGRebuild2_b64 = base64encode(file("${path.module}/scripts/jsonRAGReBuild2.sh"))
      Node1_zip_b64 = filebase64("${path.module}/projectFiles/Node1.zip")
      Node2_zip_b64 = filebase64("${path.module}/projectFiles/Node2.zip")
      Nginx_zip_b64 = filebase64("${path.module}/projectFiles/Nginx.zip")
    })
    file_name = "init-Webhook.yaml"
  }
}