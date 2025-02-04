#!/bin/bash

# Extract the IP of the service named smf2-nsmf in the open5gs namespace
EXTRACTED_IP=$(kubectl get service smf2-nsmf -n open5gs -o jsonpath='{.spec.clusterIP}')

# Check if the IP was successfully extracted
if [ -z "$EXTRACTED_IP" ]; then
  echo "Failed to extract IP for service smf2-nsmf in namespace open5gs"
  exit 1
fi

# Send the curl request to the extracted IP
curl "http://$EXTRACTED_IP:8081/subscribe"

# Output success or failure based on the curl command
if [ $? -eq 0 ]; then
  echo "Request sent successfully to http://$EXTRACTED_IP:8081/subscribe"
else
  echo "Failed to send request to http://$EXTRACTED_IP:8081/subscribe"
fi
