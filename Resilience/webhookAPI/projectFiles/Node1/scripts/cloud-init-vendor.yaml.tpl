#cloud-config

write_files:
  - path: /opt/init/.env
    permissions: '0755'
    encoding: b64
    content: ${envFile_b64}

  - path: /opt/init/install-docker.sh
    permissions: '0755'
    encoding: b64
    content: ${install_docker_b64}

  - path: /opt/init/init.sh
    permissions: '0755'
    encoding: b64
    content: ${init_b64}

  - path: /opt/init/runningProject.sh
    permissions: '0755'
    encoding: b64
    content: ${runningProject_b64}

  - path: /opt/init/cerbos.audit.conf
    permissions: '0644'
    encoding: b64
    content: ${cerbos_audit_b64}

  - path: /opt/init/cerbos_audit_stats.sh
    permissions: '0755'
    encoding: b64
    content: ${cerbos_audit_stats_b64}

  - path: /opt/init/mount-object.sh
    permissions: '0755'
    encoding: b64
    content: ${mount_object_b64}

runcmd:
  - cd /opt/init
  - ./init.sh > /var/log/init.log
  - ./install-docker.sh >> /var/log/init.log
  - ./mount-object.sh >> /var/log/init.log
  - ./runningProject.sh >> /var/log/init.log
  - echo "All scripts completed at $(date)" >> /var/log/init.log