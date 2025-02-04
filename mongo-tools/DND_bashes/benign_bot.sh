#!/usr/bin/env bash
START_TIME=$SECONDS 
END_TIME=$((START_TIME + 240))
# INTERFACE="uesimtun0"
INTERFACE="oaitun_ue1"
UE_IP=$(ip -4 addr show "$INTERFACE" | grep -oP '(?<=inet\s)10\.42\.\d+\.\d+' | head -n 1)
if [ -z "$UE_IP" ]; then
  echo "Error: Could not find an IP address for interface $INTERFACE."
  exit 1
fi

commands=(
  # "ping -I $UE_IP -c 10 google.ca"
  "curl --interface $UE_IP -H 'Host: fake-json-api.mock.beeceptor.com' http://159.89.140.122/users"
  "curl --interface $UE_IP -H 'Host: jsonplaceholder.typicode.com' http://104.21.96.1/posts"
  "curl --interface $UE_IP -H 'Host: jsonplaceholder.typicode.com' http://104.21.112.1/todos"
  "curl --interface $UE_IP -H 'Host: jsonplaceholder.typicode.com' http://104.21.48.1/posts/1/comments"
)
commands_2=(
  "curl --interface $UE_IP -H 'Host: jsonplaceholder.typicode.com' http://104.21.80.1/posts/1/comments"
  "curl --interface $UE_IP -H 'Host: jsonplaceholder.typicode.com' http://104.21.64.1/users"
  "curl --interface $UE_IP -H 'Host: jsonplaceholder.typicode.com' http://104.21.16.1/photos"
  "curl --interface $UE_IP -H 'Host: example.com' http://93.184.215.14"
)
commands_3=(
  "curl --interface $UE_IP -H 'Host: fake-json-api.mock.beeceptor.com' http://159.89.140.122/companies"
  "curl --interface $UE_IP -H 'Host: jsonplaceholder.typicode.com' http://104.21.80.1/posts/1/comments"
  "curl --interface $UE_IP -H 'Host: jsonplaceholder.typicode.com' http://104.21.64.1/users"
  "curl --interface $UE_IP -H 'Host: example.com' http://93.184.215.14"

)
commands_4=(
  "ping -I $UE_IP -c 1 google.ca"
  "curl --interface $UE_IP -H 'Host: fake-json-api.mock.beeceptor.com' http://159.89.140.122/companies"
  "ping -I $UE_IP -c 1 1.1.1.1"
  "ping -I $UE_IP -c 1 8.8.8.8"
  "ping -I $UE_IP -c 1 208.67.222.222"
  "curl --interface $UE_IP -H 'Host: jsonplaceholder.typicode.com' http://104.21.80.1/posts/1/comments"
  "curl --interface $UE_IP -H 'Host: jsonplaceholder.typicode.com' http://104.21.64.1/users"
  "curl --interface $UE_IP -H 'Host: example.com' http://93.184.215.14"
  "curl --interface $UE_IP -H 'Host: jsonplaceholder.typicode.com' http://104.21.80.1/posts/1/comments"
  "curl --interface $UE_IP -H 'Host: jsonplaceholder.typicode.com' http://104.21.64.1/users"
  "curl --interface $UE_IP -H 'Host: jsonplaceholder.typicode.com' http://104.21.16.1/photos"
  "curl --interface $UE_IP -H 'Host: example.com' http://93.184.215.14"
  "curl --interface $UE_IP -H 'Host: fake-json-api.mock.beeceptor.com' http://159.89.140.122/users"
  "curl --interface $UE_IP -H 'Host: jsonplaceholder.typicode.com' http://104.21.96.1/posts"
  "curl --interface $UE_IP -H 'Host: jsonplaceholder.typicode.com' http://104.21.112.1/todos"
  "curl --interface $UE_IP -H 'Host: jsonplaceholder.typicode.com' http://104.21.48.1/posts/1/comments"
)

while [ $SECONDS -lt $END_TIME ]; do
    random_index=$((RANDOM % ${#commands[@]}))
    cmd="${commands[$random_index]}"
    echo "Running: $cmd"
    
    result=$(eval "$cmd" 2>&1)
    status=$?
    
    echo "Result:"
    echo "$result"
    
    if [ $status -ne 0 ]; then
        echo "Error: Command failed with status $status"
    fi

    sleep_time=$(( (RANDOM % 5) + 1 ))
    sleep "$sleep_time"
done

read -p "Press Enter to start the attack behavior..."

  TARGET_IPS=(
  ‍   8.8.8.8
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
      34.107.221.82s
  )

SOURCE_INTERFACE="oaitun_ue1"
# SOURCE_INTERFACE="uesimtun0"
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

