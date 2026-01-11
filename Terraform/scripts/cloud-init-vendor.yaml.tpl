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

runcmd:
  - cd /opt/init
  - ./init.sh > /var/log/init.log
  - ./install-docker.sh >> /var/log/init.log
  - ./runningProject.sh >> /var/log/init.log
  - echo "All scripts completed at $(date)" >> /var/log/init.log