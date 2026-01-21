#cloud-config

write_files:
  - path: /opt/init/init.sh
    permissions: '0755'
    encoding: b64
    content: ${init_b64}

  - path: /opt/init/terraformDeploy.sh
    permissions: '0755'
    encoding: b64
    content: ${terraformDeploy_b64}

  - path: /opt/init/webhookDeploy.sh
    permissions: '0755'
    encoding: b64
    content: ${webhookDeploy_b64}

  - path: /opt/init/main.py
    permissions: '0644'
    encoding: b64
    content: ${main_py_b64}

  - path: /opt/init/Node1.zip
    permissions: '0644'
    encoding: b64
    content: ${Node1_zip_b64}

  - path: /opt/init/Node2.zip
    permissions: '0644'
    encoding: b64
    content: ${Node2_zip_b64}

  - path: /opt/init/Nginx1.zip
    permissions: '0644'
    encoding: b64
    content: ${Nginx1_zip_b64}

  - path: /opt/init/Nginx2.zip
    permissions: '0644'
    encoding: b64
    content: ${Nginx2_zip_b64}

  - path: /opt/init/jsonRAGReBuild1.sh
    permissions: '0755'
    encoding: b64
    content: ${jsonRAGRebuild1_b64}

  - path: /opt/init/jsonRAGReBuild2.sh
    permissions: '0755'
    encoding: b64
    content: ${jsonRAGRebuild2_b64}

  - path: /opt/init/ssl.zip
    permissions: '0644'
    encoding: b64
    content: ${ssl_zip_b64}

  - path: /opt/init/destroyAll.sh
    permissions: '0755'
    encoding: b64
    content: ${destroyAll_b64}
runcmd:
  - cd /opt/init
  - chmod +x *.sh
  - ./init.sh > /var/log/init.log 2>&1
  - ./acmeSSL.sh >> /var/log/init.log 2>&1
  - ./terraformDeploy.sh >> /var/log/init.log 2>&1
  - ./webhookDeploy.sh >> /var/log/init.log 2>&1
  - echo "All scripts completed at $(date)" >> /var/log/init.log 2>&1