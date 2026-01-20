#!/bin/bash
apt-get update && sudo apt-get install -y gnupg software-properties-common
wget -O- https://apt.releases.hashicorp.com/gpg | \
gpg --dearmor | \
tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null
gpg --no-default-keyring \
--keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg \
--fingerprint
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list
apt update
apt-get install terraform -y
mkdir -p /data/sshkeys
# Add your public SSH key here
cat > /data/sshkeys/id_ed25519.pub <<'EOF'
-----BEGIN OPENSSH PUBLIC KEY-----

-----END OPENSSH PUBLIC KEY-----
EOF
# Node1
export HOME=/root
mkdir -p /data/jsonRAG/Node1
cp /opt/init/Node1.zip /data/jsonRAG/Node1/Node1.zip
cd /data/jsonRAG/Node1
unzip Node1.zip
rm Node1.zip
terraform init
terraform plan
terraform apply -auto-approve
# Node2
mkdir -p /data/jsonRAG/Node2
cp /opt/init/Node2.zip /data/jsonRAG/Node2/Node2.zip
cd /data/jsonRAG/Node2
unzip Node2.zip
rm Node2.zip
terraform init
terraform plan
terraform apply -auto-approve
# Nginx
mkdir -p /data/jsonRAG/Nginx
cp /opt/init/Nginx.zip /data/jsonRAG/Nginx/Nginx.zip
cd /data/jsonRAG/Nginx
unzip Nginx.zip
rm Nginx.zip
terraform init
terraform plan
terraform apply -auto-approve