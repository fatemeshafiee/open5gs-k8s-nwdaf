#!/bin/bash

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <directory_name>"
  exit 1
fi

directory_name=$1
namespace="open5gs"


SOURCE_INTERFACE="uesimtun0"


check_pods_running() {
  local label=$1
  echo "Checking if all pods with label '$label' in namespace '$namespace' are running..."
  while true; do
    local non_running_pods
    non_running_pods=$(kubectl get pods -l $label -n "$namespace" --field-selector=status.phase!=Running -o jsonpath='{.items[*].metadata.name}')
    if [ -z "$non_running_pods" ]; then
      echo "All pods with label '$label' are running."
      break
    else
      echo "Non-running pods: $non_running_pods"
      echo "Waiting for all pods with label '$label' to be running..."
      sleep 5
    fi
  done
}

wait_for_no_resources() {
  echo "Waiting for all pods in namespace '$namespace' to be removed (excluding mlflow and postgresql)..."
  while true; do
    local pods
    pods=$(kubectl get pods -n "$namespace" --no-headers | grep -vE "mlflow|postgresql" | awk '{print $1}')
    if [ -z "$pods" ]; then
      echo "All non-mlflow and non-postgresql pods removed in namespace '$namespace'."
      break
    else
      echo "Pods still present (excluding mlflow and postgresql): $pods"
      sleep 5
    fi
  done
}
for U in 5; do
  echo "----------------------"
  echo "Starting experiment with UEs: ${U}"
  echo "----------------------"

  kubectl apply -k mongodb -n "$namespace"
  check_pods_running "app=mongodb"

  kubectl apply -k open5gs -n "$namespace"
  check_pods_running "app=open5gs"

  kubectl apply -k ueransim/ueransim-gnb/ -n "$namespace"
  check_pods_running "app=gnb"

  kubectl apply -k NWDAF/MLflow/ -n open5gs
  check_pods_running "app=mlflow"
  sleep 23

  ./log_model_v2.sh
  sleep 5
  kubectl apply -k NWDAF/ -n "$namespace"
  sleep 15

  echo "Deploying UE $i"
  ue_path="ueransim/ueransim-ue/"
  kubectl apply -k "$ue_path" -n "$namespace"

  for ((i = 1; i <= U; i++)); do
  if [ -d "$ue_path" ]; then
    check_pods_running "app=ueransim,component=ue,name=ue${i}"
  else
    echo "Directory not found for UE $i at $ue_path, skipping."
  fi
  done
  ./sub_smf.sh

  log_dir="${directory_name}"
  mkdir -p "$log_dir"

  kubectl apply -f fake-target/fake-target.yaml -n open5gs
  check_pods_running "app=fake-proxy"
  sleep 5
  ue_1=$(kubectl get pods -n "$namespace" -l "app=ueransim,component=ue,name=ue1" -o jsonpath='{.items[0].metadata.name}')
  
(
  PING_LOG="$log_dir/ue_ping_monitor.log"
  echo "🌐 Starting continuous ping monitor at $(date -u '+%Y-%m-%d %H:%M:%S.%3N')" > "$PING_LOG"

  START_TIME=$(date +%s)
  DURATION=75 # seconds

  while true; do
    CURRENT_TIME=$(date +%s)
    ELAPSED=$((CURRENT_TIME - START_TIME))

    if [ "$ELAPSED" -ge "$DURATION" ]; then
      echo "⏹️ Ping monitor stopped after $DURATION seconds at $(date -u '+%Y-%m-%d %H:%M:%S.%3N')" >> "$PING_LOG"
      break
    fi

    TIMESTAMP=$(date -u '+%Y-%m-%d %H:%M:%S.%3N')
    timeout 0.2s kubectl exec -n "$namespace" "$ue_1" -- ping -I "$SOURCE_INTERFACE" -c 1 8.8.8.8 > /dev/null 2>&1

    if [ $? -ne 0 ]; then
      echo "❌ Ping failed at $TIMESTAMP" >> "$PING_LOG"
    else
      echo "✅ Ping successful at $TIMESTAMP" >> "$PING_LOG"
    fi

    sleep 1
  done
) &

  TARGET_IPS=($(kubectl get pods -n "$namespace" -l app=fake-proxy -o jsonpath='{range .items[*]}{.status.podIP}{" "}{end}'))
  for TARGET_IP in "${TARGET_IPS[@]}"; do
  echo "Adding route to $TARGET_IP via $SOURCE_INTERFACE in $ue_1"
  kubectl exec -n "$namespace" "$ue_1" -- ip route add "$TARGET_IP" dev "$SOURCE_INTERFACE" || echo "Route to $TARGET_IP may already exist or failed."
  done

  (
    ATTACK_LOG=$log_dir/attack.log
    START_HUMAN=$(date -u '+%Y-%m-%d %H:%M:%S.%3N')
    echo "Ping test started at $START_HUMAN" > "$ATTACK_LOG"
    S_TIME=$(date +%s)
    DURATION=60  # seconds

    declare -a pids=()

    while [ $(( $(date +%s) - $S_TIME )) -lt $DURATION ]; do
      echo "⏳ New scan round at $(date -u '+%Y-%m-%d %H:%M:%S.%3N')" >> "$ATTACK_LOG"
      kubectl exec -n "$namespace" "$ue_1" -- ping -I "$SOURCE_INTERFACE" -c 1 8.8.8.8
      SELECTED_TARGETS=($(shuf -e "${TARGET_IPS[@]}" | head -n 10))

      for TARGET_IP in "${SELECTED_TARGETS[@]}"; do
        (

          RESULT=$(kubectl exec -n "$namespace" "$ue_1" -- \
            nmap -e "$SOURCE_INTERFACE" -p 8080,3128,8000,8888,1080 \
            --script http-open-proxy -T4 --max-retries 1 -n "$TARGET_IP" 2>&1)

          TIMESTAMP=$(date -u '+%Y-%m-%d %H:%M:%S.%3N')

          if echo "$RESULT" | grep -q "open proxy"; then
            echo "🔥 $TARGET_IP is an open proxy at $TIMESTAMP" >> "$ATTACK_LOG"
          else
            echo "$TARGET_IP not open at $TIMESTAMP" >> "$ATTACK_LOG"
          fi

          echo "$RESULT" >> "$ATTACK_LOG"
        ) &
        pids+=($!)  # Collect PID
      done

      sleep 5
    done

    # Wait for all background scan jobs to finish
    for pid in "${pids[@]}"; do
      wait "$pid"
    done

    TIMESTAMP=$(date -u '+%Y-%m-%d %H:%M:%S.%3N')
    echo "✅ All background scans completed at $TIMESTAMP" >> "$ATTACK_LOG"
  ) &
  scan_pid=$!
  wait $scan_pid

  # to do when all the back grounds done log the time in attack log
  # ------------------------------------------------------------------

  # Extract logs from key components
  kubectl logs -n "$namespace" deployment/open5gs-upf2 | grep "\[Report_Latency\]" > "$log_dir/upf.log"
  kubectl logs -n "$namespace" deployment/open5gs-smf2 | grep -E "\[Report_Latency\]|\[Notif_Latency\]" > "$log_dir/smf.log"
  kubectl logs -n "$namespace" deployment/nwdaf-sbi | grep "\[DSN_Latency\]" > "$log_dir/nwdaf_sbi.log"
  kubectl logs -n "$namespace" deployment/nwdaf-nbi-events | grep "Sending notification to client" > "$log_dir/nwdaf_nbi.log"
  kubectl logs -n "$namespace" deployment/nwdaf-engine-bot-detection | grep "\[Report_Latency\]" > "$log_dir/bot_engine.log"
  
  #engine log 

  ./undeploy.sh
  kubectl delete -f fake-target/fake-target.yaml -n open5gs
  wait_for_no_resources

  echo "Resources undeployed for experiment ${U}. Waiting before next iteration..."
  sleep 10
done

echo "🎉 All experiments completed."
