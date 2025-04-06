#!/bin/bash

mkdir /dev/net
mknod /dev/net/tun c 10 200

/ueransim/nr-ue -c /ueransim/config/ue4.yaml
# &
# sleep 10 
# START_TIME=$SECONDS 
# END_TIME=$((START_TIME + 120))
# INTERFACE="uesimtun0"
# UE_IP=$(ip -4 addr show "$INTERFACE" | grep -oP '(?<=inet\s)10\.42\.\d+\.\d+' | head -n 1)
# if [ -z "$UE_IP" ]; then
#   echo "Error: Could not find an IP address for interface $INTERFACE."
#   exit 1
# fi

# while [ $SECONDS -lt $END_TIME ]; do
#     cmd="ping -i 1 -I $UE_IP -c 3 8.8.8.8"
#     echo "Running: $cmd"
    
#     result=$(eval "$cmd" 2>&1)
#     status=$?
    
#     echo "Result:"
#     echo "$result"
    
#     if [ $status -ne 0 ]; then
#         echo "Error: Command failed with status $status"
#     fi

#     sleep_time=2
#     sleep "$sleep_time"
# done
# tail -f /dev/null