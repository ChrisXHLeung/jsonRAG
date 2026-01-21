#!/bin/bash
set -e
export HOME=/root
apt update && apt install -y keepalived
cat >> /etc/keepalived/keepalived.conf<< EOF
global_defs {
   router_id jsonRAG_Nginx2
   vrrp_garp_master_refresh 60
   vrrp_garp_master_refresh_repeat 2
}

vrrp_instance jsonRAG {
    state BACKUP
    nopreempt
    interface eth0
    virtual_router_id 22
    priority 100
    advert_int 2
    authentication {
        auth_type PASS
        auth_pass <Your_Auth_Password>
    }
    virtual_ipaddress {
        <Your_VIP_Address>/24
    }
}
EOF
systemctl restart keepalived
systemctl enable keepalived
