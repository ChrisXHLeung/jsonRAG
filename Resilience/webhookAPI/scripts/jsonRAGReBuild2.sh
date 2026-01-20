#!/bin/bash

# Configuration
TARGET_DIR="/data/jsonRAG/Node2"
LOG_FILE="/var/log/jsonRAG_script2.log"
export TF_IN_AUTOMATION=true
export TF_LOG=INFO
export PATH=$PATH:/usr/local/bin:/usr/bin

# Function to log messages with timestamps
log_msg() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Change directory
cd "$TARGET_DIR" || { log_msg "ERROR: Cannot access directory $TARGET_DIR"; exit 1; }

log_msg "--- Starting RAG Infrastructure Rebuild ---"

# Execute Terraform Destroy
log_msg "Step 1/2: Executing Terraform Destroy..."
terraform destroy -auto-approve -no-color -input=false 2>&1 | tee -a "$LOG_FILE"

if [ ${PIPESTATUS[0]} -ne 0 ]; then
    log_msg "ERROR: Terraform Destroy failed."
    exit 1
fi

# Execute Terraform Apply
log_msg "Step 2/2: Executing Terraform Apply..."
terraform apply -auto-approve -no-color -input=false 2>&1 | tee -a "$LOG_FILE"

if [ ${PIPESTATUS[0]} -ne 0 ]; then
    log_msg "ERROR: Terraform Apply failed."
    exit 1
fi

log_msg "--- Rebuild Completed Successfully ---"
