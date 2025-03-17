#!/usr/bin/env bash
START_TIME=$SECONDS 
END_TIME=$((START_TIME + 3600))
INTERFACE="uesimtun0"
UE_IP=$(ip -4 addr show "$INTERFACE" | grep -oP '(?<=inet\s)10\.42\.\d+\.\d+' | head -n 1)
if [ -z "$UE_IP" ]; then
  echo "Error: Could not find an IP address for interface $INTERFACE."
  exit 1
fi

commands=(
  "ping -I $UE_IP -c 10 google.ca"
  "curl --interface $UE_IP -H 'Host: fake-json-api.mock.beeceptor.com' http://159.89.140.122/users"
  "curl --interface $UE_IP -H 'Host: fake-json-api.mock.beeceptor.com' http://159.89.140.122/companies"
  "curl --interface $UE_IP -H 'Host: fake-json-api.mock.beeceptor.com' http://159.89.140.122/customers"
  "curl --interface $UE_IP -H 'Host: jsonplaceholder.typicode.com' http://104.21.96.1/posts"
  "curl --interface $UE_IP -H 'Host: jsonplaceholder.typicode.com' http://104.21.96.1/albums"
  "curl --interface $UE_IP -H 'Host: jsonplaceholder.typicode.com' http://104.21.112.1/todos"
  "curl --interface $UE_IP -H 'Host: jsonplaceholder.typicode.com' http://104.21.48.1/posts/1/comments"
  "curl --interface $UE_IP http://142.250.190.78"
  "ping -I $UE_IP -c 3 http://93.184.215.14"
)
commands_2=(
  "curl --interface $UE_IP -H 'Host: jsonplaceholder.typicode.com' http://104.21.80.1/posts/1/comments"
  "curl --interface $UE_IP -H 'Host: jsonplaceholder.typicode.com' http://104.21.64.1/users"
  "curl --interface $UE_IP -H 'Host: jsonplaceholder.typicode.com' http://104.21.16.1/photos"
  "curl --interface $UE_IP -H 'Host: example.com' http://93.184.215.14"
  "curl --interface $UE_IP http://1.1.1.1"
  "curl --interface $UE_IP http://93.184.216.34"
  "ping -I $UE_IP -c 1 8.8.8.8"
  "ping -I $UE_IP -c 2 4.2.2.2"
)
while [ $SECONDS -lt $END_TIME ]; do
    cmd="ping -I $UE_IP -c 3 google.ca"
    echo "Running: $cmd"
    
    result=$(eval "$cmd" 2>&1)
    status=$?
    
    echo "Result:"
    echo "$result"
    
    if [ $status -ne 0 ]; then
        echo "Error: Command failed with status $status"
    fi

    sleep_time=0.3
    sleep "$sleep_time"
done