#!/bin/bash
set -e

cd /opt/init
unzip -o ssl.zip
rm -f ssl.zip

apt update
apt install -y nginx

cp -rf nginx.conf /etc/nginx/nginx.conf
cp -rf auth.conf /etc/nginx/conf.d/auth.conf

systemctl daemon-reload || true
systemctl enable nginx
systemctl restart nginx || true