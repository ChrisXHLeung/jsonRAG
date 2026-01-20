#cloud-config
write_files:
  - path: /opt/init/init.sh
    permissions: '0755'
    encoding: b64
    content: ${init_b64}

  - path: /opt/init/runningProject.sh
    permissions: '0755'
    encoding: b64
    content: ${runningProject_b64}

  - path: /opt/init/nginx.conf
    permissions: '0644'
    encoding: b64
    content: ${nginx_conf_b64}

  - path: /opt/init/auth.conf
    permissions: '0644'
    encoding: b64
    content: ${auth_conf_b64}

runcmd:
  - cd /opt/init
  - ./init.sh > /var/log/init.log
  - ./runningProject.sh >> /var/log/init.log
  - echo "All scripts completed at $(date)" >> /var/log/init.log