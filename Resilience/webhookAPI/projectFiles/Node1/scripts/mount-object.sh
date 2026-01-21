#!/bin/bash

# --- Configuration Section ---
REMOTE_NAME=<Your_Rclone_Remote_Name>
BUCKET_NAME=<Your_Bucket_Name>
MOUNT_PATH=</path/to/mount/point>
MINIO_URL=<Your_MinIO_Server_URL>
ACCESS_KEY=<Your_Access_Key>
SECRET_KEY=<Your_Secret_Key>
RCLONE_BIN=$(which rclone || echo "/usr/bin/rclone")
CONF_FILE="/root/.config/rclone/rclone.conf"
# ----------------------------

# 1. Ensure rclone is installed
export DEBIAN_FRONTEND=noninteractive
if ! command -v rclone &> /dev/null; then
    curl https://rclone.org/install.sh | sudo bash
fi

# 2. Create Config
mkdir -p $(dirname "$CONF_FILE")
cat > "$CONF_FILE" <<EOF
[$REMOTE_NAME]
type = s3
provider = Minio
access_key_id = $ACCESS_KEY
secret_access_key = $SECRET_KEY
endpoint = $MINIO_URL
EOF

# 3. Prepare Mount Point
# Unmount if already mounted to avoid "transport endpoint is not connected"
if mountpoint -q "$MOUNT_PATH"; then
    sudo fusermount -u "$MOUNT_PATH"
fi
mkdir -p "$MOUNT_PATH"

# 4. Wait for Network & MinIO
MAX_RETRIES=10
COUNT=0
until curl -s "$MINIO_URL" > /dev/null || [ $COUNT -eq $MAX_RETRIES ]; do
    sleep 5
    COUNT=$((COUNT+1))
done

# 5. Execute Mount with REAL-TIME SYNC parameters
# --dir-cache-time 5s: Refresh the folder list every 5 seconds
# --poll-interval 1s: Check for cloud changes every 1 second
# --attr-timeout 1s: Expire file metadata (size, date) after 1 second

$RCLONE_BIN mount "$REMOTE_NAME:$BUCKET_NAME" "$MOUNT_PATH" \
    --config "$CONF_FILE" \
    --vfs-cache-mode full \
    --vfs-cache-max-size 10G \
    --dir-cache-time 5s \
    --poll-interval 1s \
    --attr-timeout 1s \
    --allow-other \
    --daemon \
    --log-file /var/log/rclone-mount.log \
    --log-level INFO

# 6. Verify and Log
sleep 2
if mountpoint -q "$MOUNT_PATH"; then
    echo "Mount Successful"
else
    echo "Mount Failed - Check /var/log/rclone-mount.log"
    exit 1
fi