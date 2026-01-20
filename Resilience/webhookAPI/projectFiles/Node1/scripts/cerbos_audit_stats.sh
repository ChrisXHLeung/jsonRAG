#!/bin/bash

# Configuration
AUDIT_FILE="/data/jsonRAG/PDP/audit/audit.json"
TENANT_ID="$1"
MODE="$2"

# Validation
if [ -z "$TENANT_ID" ] || [ -z "$MODE" ]; then
    echo "0"
    exit 1
fi

if [ ! -f "$AUDIT_FILE" ]; then
    echo "0"
    exit 0
fi

# Map mode to Cerbos Effect string
if [ "$MODE" = "deny" ]; then
    TARGET_EFFECT="EFFECT_DENY"
else
    TARGET_EFFECT="EFFECT_ALLOW"
fi

# Calculate ISO8601 timestamp for 1 hour ago in UTC
CUTOFF=$(date -u -d "1 hour ago" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u -v-1H +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null)

# Logic:
# 1. Filter decision logs in the last hour for the specific tenant.
# 2. Filter for "Real Requests": Only count if the number of requested actions is exactly 1.
#    (Polling sends 3 actions: read, update, delete. Real clicks send only 1).
# 3. Match the target effect and count unique CallIDs.

cat "$AUDIT_FILE" | jq -s -r --arg cutoff "$CUTOFF" --arg tenant "$TENANT_ID" --arg effect "$TARGET_EFFECT" '
  .[] 
  | select(.["log.kind"] == "decision" and .timestamp >= $cutoff)
  | select(.checkResources.inputs[].principal.attr.tenantId == $tenant)
  | .checkResources as $cr
  | select(($cr.inputs[0].actions | length) == 1)
  | select($cr.outputs[].actions[].effect == $effect)
  | .callId
' | sort | uniq | wc -l