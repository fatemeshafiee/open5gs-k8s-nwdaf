#!/bin/bash
end=$((SECONDS+240))
# INTERFACE="uesimtun0"
INTERFACE="oaitun_ue1"
UE_IP=$(ip -4 addr show "$INTERFACE" | grep -oP '(?<=inet\s)10\.42\.\d+\.\d+' | head -n 1)
for i in {1..24}; do
    curl  --interface $UE_IP -X POST http://129.97.168.51:5000/heartbeat -H "Content-Type: application/json" -d '{"device_id": "sensor_123"}'
    sleep 10
done
read -p "Press Enter to start the suspicious unusual downloading behavior..."


server_line=$(speedtest --list | head -n 2 | tail -n 1)
server_id=$(echo "$server_line" | sed -E 's/^\s*([0-9]+).*/\1/')
echo "Using server ID: $server_id"
speedtest --server "$server_id" --no-upload
speedtest --server "$server_id" --no-upload
wget https://getsamplefiles.com/download/zip/sample-1.zip -O sample-1.zip
wget https://file-examples.com/wp-content/storage/2017/02/zip_10MB.zip -O zip_10MB.zip
speedtest --server "$server_id" --no-upload
speedtest --server "$server_id" --no-upload
read -p "Press Enter to start the bot behavior..."

# List of 30 target IPs
TARGET_IPS=(
    8.8.8.8
    1.1.1.1
    208.67.222.222
    8.8.4.4
    9.9.9.9
    4.2.2.2
    1.0.0.1
    64.233.187.99
    172.217.169.238
    143.204.90.96
    13.227.253.87
    216.58.207.238
    185.60.216.35
    31.13.71.36
    172.217.16.196
    142.250.74.206
    151.101.1.69
    104.16.133.176
    52.85.151.44
    34.107.221.82
    192.168.1.1
    185.199.108.153
    104.244.42.129
    34.117.59.81
    185.199.109.153
    104.18.26.46
    104.18.27.46
    151.101.129.69
    104.21.234.89
)

# Specify the source interface
SOURCE_INTERFACE="oaitun_ue1"

# Log file to store results
LOG_FILE="nmap_results.log"
echo "TCP SYN scan started at $(date)" > "$LOG_FILE"

START_TIME=$(date +%s)

DURATION=60
echo "Sending TCP SYN packets using nmap for $DURATION seconds..."

# Loop until the duration is reached
echo "Starting attack for $DURATION seconds..."
START_TIME=$(date +%s)

# Loop until the duration is reached
while [ $(( $(date +%s) - START_TIME )) -lt $DURATION ]; do
    for TARGET_IP in "${TARGET_IPS[@]}"; do
        # Check if the total duration is exceeded
        if [ $(( $(date +%s) - START_TIME )) -ge $DURATION ]; then
            break
        fi

        echo "Reaching the target $TARGET_IP from interface $SOURCE_INTERFACE..."
        
        if ping -I "$SOURCE_INTERFACE" -c 1 -W 1 "$TARGET_IP" > /dev/null 2>&1; then
            echo "$TARGET_IP is reachable ✅"
        else
            echo "$TARGET_IP is unreachable ❌"
            continue # Skip scanning if the host is unreachable
        fi

        
        RANDOM_PORT=$((RANDOM % 65535 + 1))

        echo "Scanning $TARGET_IP on port $RANDOM_PORT using interface $SOURCE_INTERFACE..."
        
        nmap -sS -p "$RANDOM_PORT" -e "$SOURCE_INTERFACE" "$TARGET_IP" > /dev/null 2>&1

        sleep 0.5
    done
done

echo "Finished attacking for $DURATION seconds."
 

