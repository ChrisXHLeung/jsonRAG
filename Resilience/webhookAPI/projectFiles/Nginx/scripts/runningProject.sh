#!/bin/bash
set -e
export HOME=/root
cd /root/
curl https://get.acme.sh | sh -s email=<email_here>
/root/.acme.sh/acme.sh --register-account --accountemail <email_here>
# echo "SAVED_CF_Token='<token_here>'" >> /root/.acme.sh/account.conf

/root/.acme.sh/acme.sh --set-default-ca --server letsencrypt
/root/.acme.sh/acme.sh --issue --dns dns_cf -d <your domain> --keylength ec-256
apt-get update
apt-get install -y nginx

mkdir -p /etc/nginx/ssl/<your domain>/
# copy certs
# ln -sf /root/.acme.sh/<your domain>_ecc/fullchain.cer /etc/nginx/ssl/<your domain>/fullchain.cer
# ln -sf /root/.acme.sh/<your domain>_ecc/<your domain>.key /etc/nginx/ssl/<your domain>/<your domain>.key

cp -rf /opt/init/nginx.conf /etc/nginx/nginx.conf
cp -rf /opt/init/auth.conf /etc/nginx/conf.d/auth.conf

systemctl restart nginx
systemctl enable nginx