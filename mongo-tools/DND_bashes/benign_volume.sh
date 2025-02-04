#!/bin/bash
end=$((SECONDS+240))
INTERFACE="uesimtun0"
UE_IP=$(ip -4 addr show "$INTERFACE" | grep -oP '(?<=inet\s)10\.42\.\d+\.\d+' | head -n 1)
for i in {1..24}; do
    curl  --interface $UE_IP -X POST http://129.97.168.51:5000/heartbeat -H "Content-Type: application/json" -d '{"device_id": "sensor_123"}'
    sleep 10
done

# Download a file after 4 minutes
read -p "Press Enter to start the suspicious unusual downloading behavior..."


server_line=$(speedtest --list | head -n 2 | tail -n 1)
server_id=$(echo "$server_line" | sed -E 's/^\s*([0-9]+).*/\1/')
echo "Using server ID: $server_id"
speedtest --server "$server_id" --no-upload
speedtest --server "$server_id" --no-upload
wget https://getsamplefiles.com/download/zip/sample-1.zip -O sample-1.zip
wget https://file-examples.com/wp-content/storage/2017/02/zip_10MB.zip -O zip_10MB.zip
speedtest --server "$server_id" --no-upload
speedtest --server "$server_id" --no-uploads