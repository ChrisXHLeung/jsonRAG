#!/bin/bash

mkdir /data/
cd /data
# Clone the repository
git clone https://github.com/ChrisXHLeung/jsonRAG.git
cd jsonRAG
/bin/mount -t nfs 192.168.10.201:/data/jsonRAG_NFS /data/jsonRAG/PEP/storage
# create network
docker network create jsonRAG
# run PDP server
cd PDP
mkdir /data/jsonRAG/PDP/audit
touch /data/jsonRAG/PDP/audit/audit.json
docker run -d --name cerbos \
  --network jsonRAG \
  -p 3592:3592 -p 3593:3593 \
  -v $(pwd)/policies:/policies \
  -v $(pwd)/conf.yaml:/conf.yaml \
  -v $(pwd)/audit:/audit \
  ghcr.io/cerbos/cerbos:latest server --config=/conf.yaml
cd ..
# run PEP server
cd PEP
docker build -t json_rag .
docker run -d \
  --network jsonRAG \
  -p 3000:3000 \
  --env-file=/opt/init/.env \
  -v /mnt/rag_data:/app/storage \
  --name cerbosRAG \
  json_rag