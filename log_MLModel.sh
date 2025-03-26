#!/bin/bash

# Step 1: Use localhost since we are using port-forwarding
SERVICE_IP="localhost"
PORT="8000"

echo "Using local port-forwarded address..."
echo "Found service IP: $SERVICE_IP"

# Step 2: Google Drive direct download link
GDRIVE_FILE_ID="10wTHq5JtcNKi1GFkf2xSN3eIYHxwATnZ"
DIRECT_DOWNLOAD_URL="https://drive.google.com/uc?export=download&id=${GDRIVE_FILE_ID}"

# Step 3: Create the JSON payload
read -r -d '' PAYLOAD <<EOF
{
  "model_name": "abnormal-behaviour-detector",
  "model_url": "${DIRECT_DOWNLOAD_URL}",
  "mLEvent": {
    "nwdafEvent": "ABNORMAL_BEHAVIOUR"
  },
  "event_filter": null,
  "inference_data": null,
  "target_ue": null,
  "is_update": false
}
EOF

# Step 4: Send the request
echo "🚀 Sending POST request to http://${SERVICE_IP}:${PORT}/log_model/ ..."
curl -X POST "http://${SERVICE_IP}:${PORT}/log_model/" \
     -H "Content-Type: application/json" \
     -d "$PAYLOAD"

echo -e "\n✅ Request complete."
