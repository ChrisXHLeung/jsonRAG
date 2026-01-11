#!/bin/bash
apt-get update
apt-get install -y ca-certificates curl gnupg
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

usermod -aG docker <your-username>

docker network create Portainer

# optional: Install Portainer for Docker management
#docker run -d \
#  -p 19000:9000 \
#  --name=Portainer \
#  --restart=always \
#  --network=Portainer \
#  -v /var/run/docker.sock:/var/run/docker.sock \
#  -v portainer_data:/data \
#  portainer/portainer-ce:alpine