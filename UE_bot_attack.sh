#!/bin/bash

# Log file to store results
LOG_FILE="UE_attack.log"

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
SOURCE_INTERFACE="uesimtun0"

# Start log
START_DATETIME=$(date '+%Y-%m-%d %H:%M:%S')
echo "Ping test started at $START_DATETIME" > "$LOG_FILE"

# Total duration for which the script should run (in seconds)
DURATION=60
START_TIME=$(date +%s)

echo "Running ping loop using interface $SOURCE_INTERFACE for $DURATION seconds..."

# Loop until the duration is reached
while [ $(( $(date +%s) - START_TIME )) -lt $DURATION ]; do
    for TARGET_IP in "${TARGET_IPS[@]}"; do
        # Stop if time is up
        if [ $(( $(date +%s) - START_TIME )) -ge $DURATION ]; then
            break
        fi

        echo "Pinging $TARGET_IP using interface $SOURCE_INTERFACE..."

        # Send a single ping with timeout, interval set to 0.01s
        ping -I "$SOURCE_INTERFACE" -c 1 -W 1 -i 0.01 "$TARGET_IP" > /dev/null 2>&1

        if [ $? -eq 0 ]; then
            echo "$TARGET_IP responded to ping ✅" | tee -a "$LOG_FILE"
        else
            echo "$TARGET_IP did not respond to ping ❌ at $(date '+%Y-%m-%d %H:%M:%S')" | tee -a "$LOG_FILE"
        fi

    done
done

echo "Ping test completed at $(date '+%Y-%m-%d %H:%M:%S')" >> "$LOG_FILE"
