#!/bin/bash
set -e

apt-get update
apt-get install -y \
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
  python3-pip
# Configure SSH to use stronger ciphers and key exchange algorithms
sed -i '28a\Ciphers aes128-ctr,aes192-ctr,aes256-ctr,aes128-gcm@openssh.com,aes256-gcm@openssh.com' /etc/ssh/sshd_config
sed -i '29a\KexAlgorithms diffie-hellman-group-exchange-sha256' /etc/ssh/sshd_config
systemctl restart sshd