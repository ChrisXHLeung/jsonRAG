#!/bin/bash
cd /data/jsonRAG/Node1
terraform destroy -auto-approve
cd /data/jsonRAG/Node2
terraform destroy -auto-approve
cd /data/jsonRAG/Nginx1
terraform destroy -auto-approve
cd /data/jsonRAG/Nginx2
terraform destroy -auto-approve