#!/bin/bash

# Configuration
SERVICE_NAME="modelprov-svc"
NAMESPACE="open5gs"
PORT="8000"

echo "📡 Fetching service IP for $SERVICE_NAME in namespace $NAMESPACE..."

# Try to get LoadBalancer IP first, fallback to ClusterIP
SERVICE_IP=$(kubectl get svc "$SERVICE_NAME" -n "$NAMESPACE" \
  -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

if [ -z "$SERVICE_IP" ]; then
  SERVICE_IP=$(kubectl get svc "$SERVICE_NAME" -n "$NAMESPACE" \
    -o jsonpath='{.spec.clusterIP}')
fi

if [ -z "$SERVICE_IP" ]; then
  echo "❌ Failed to get a valid IP for $SERVICE_NAME in $NAMESPACE"
  exit 1
fi

echo "✅ Found service IP: $SERVICE_IP"

# Direct download URL from Google Drive
GDRIVE_FILE_ID="10wTHq5JtcNKi1GFkf2xSN3eIYHxwATnZ"
DIRECT_DOWNLOAD_URL="https://drive.google.com/uc?export=download&id=${GDRIVE_FILE_ID}"

# JSON Payload for the log_model request
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

# Sending the POST request
echo "🚀 Sending POST request to http://${SERVICE_IP}:${PORT}/log_model/ ..."
curl -X POST "http://${SERVICE_IP}:${PORT}/log_model/" \
     -H "Content-Type: application/json" \
     -d "$PAYLOAD"

echo -e "\n✅ Request complete."
