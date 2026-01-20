#!/bin/bash
apt install -y python3 python3-venv python3-pip
mkdir -p /data/webhook /var/log/webhook /scripts
cp /opt/init/main.py /data/webhook/main.py
chmod 755 /data /data/webhook /var/log/webhook /scripts
cd /data/webhook
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install fastapi uvicorn requests
cat > /etc/systemd/system/webhook.service <<'EOF'
[Unit]
Description=Webhook API for RAG Rebuild
After=network.target

[Service]
User=root
WorkingDirectory=/data/webhook
ExecStart=/data/webhook/venv/bin/uvicorn main:app --host 0.0.0.0 --port 8000
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable webhook
systemctl start webhook
systemctl status webhook

