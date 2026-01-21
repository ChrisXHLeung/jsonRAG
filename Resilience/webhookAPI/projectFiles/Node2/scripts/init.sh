#!/bin/bash
set -e

apt-get update
apt-get install -y \
  rclone \
  net-tools \
  iftop \
  tcpdump \
  tree \
  vim \
  curl \
  psmisc \
  lrzsz \
  wget \
  bash-completion \
  dos2unix \
  lsof \
  sysstat \
  unzip \
  rsync \
  git \
  ca-certificates \
  build-essential \
  jq \
  python3 \
  python3-pip \
  jq \
  acl

# Install Zabbix Agent
wget https://repo.zabbix.com/zabbix/7.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_latest_7.0+ubuntu24.04_all.deb
dpkg -i zabbix-release_latest_7.0+ubuntu24.04_all.deb
apt update
apt install zabbix-agent -y
# Configure Zabbix Agent
sed -i 's/^ServerActive=/# ServerActive=/g' /etc/zabbix/zabbix_agentd.conf
sed -i 's/^Server=/# Server=/g' /etc/zabbix/zabbix_agentd.conf
sed -i 's/^Hostname=/# Hostname=/g' /etc/zabbix/zabbix_agentd.conf
cat >> /etc/zabbix/zabbix_agentd.conf << EOF
Server= <your_zabbix_server_ip_or_hostname>
ServerActive= <your_zabbix_server_ip_or_hostname>
ListenPort= <Your_desired_port>
EOF
cp /opt/init/cerbos.audit.conf /etc/zabbix/zabbix_agentd.d/cerbos.audit.conf
# Restart Zabbix Agent
systemctl restart zabbix-agent
systemctl enable zabbix-agent