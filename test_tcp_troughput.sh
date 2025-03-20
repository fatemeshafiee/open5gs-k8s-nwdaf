#!/bin/bash

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <directory_name>"
  exit 1
fi

directory_name=$1
namespace="open5gs"
server_ip="129.97.168.65"  

check_pods_running() {
  local label=$1
  echo "Checking if all pods with label $label in namespace '$namespace' are running..."
  while true; do
    local non_running_pods=$(kubectl get pods -l $label -n "$namespace" --field-selector=status.phase!=Running -o jsonpath='{.items[*].metadata.name}')
    if [ -z "$non_running_pods" ]; then
      echo "All pods with label $label are running in $namespace."
      break
    else
      echo "Non-running pods: $non_running_pods"
      echo "Waiting for all pods with label $label to be running in $namespace..."
      sleep 5
    fi
  done
}

kubectl apply -k mongodb -n $namespace
check_pods_running "app=mongodb"

kubectl apply -k open5gs -n $namespace
check_pods_running "app=open5gs"

# kubectl apply -k NWDAF -n $namespace
# check_pods_running "app=nwdaf-sbi"

# sleep 60
kubectl apply -k ueransim/ueransim-gnb/ -n $namespace
check_pods_running "app=gnb"

mkdir -p "${directory_name}"
for i in $(seq 1 10); do 
  kubectl apply -k ueransim/ueransim-ue/ue$i -n $namespace
  check_pods_running "app=ueransim,component=ue,name=ue$i"
  dir_name="$(pwd)/${directory_name}"
  echo "Directory $dir_name Creating now..."
  resource_log_filename="${directory_name}/upf-resources-step${i}.log"
  echo "Monitoring CPU and Memory usage of UPF during UE$i deployment..." > "$resource_log_filename"
  
  for second in {1..100}; do
    echo "$(date +"%Y-%m-%d %H:%M:%S") - Monitoring cycle $second" >> "$resource_log_filename"
    kubectl top pod -n $namespace | grep "upf" >> "$resource_log_filename"
    sleep 0.1
  done &

  # For each new UE, run iPerf3 from UE1 to UEi
  for j in $(seq 1 $i); do
    
    pod_name=$(kubectl get pods -n $namespace -l "app=ueransim,component=ue,name=ue$j" -o jsonpath='{.items[0].metadata.name}')
    echo "Pod name found: '$pod_name'"
    if [ -z "$pod_name" ]; then
        echo "No pod found with 'name=ue$i'"
      continue
    fi
    INTERFACE="uesimtun0"
    UE_IP=$(kubectl exec "$pod_name" -n "$namespace" -- bash -c \
    "ip -4 addr show $INTERFACE | grep -oP '(?<=inet\s)10\.42\.\d+\.\d+' | head -n 1")
    tcp_log_filename="${dir_name}/tcp_step_${i}UE${j}.log"
    port=$((5000 + j))
    echo "Detected UE IP from the UPF container: $UE_IP"
    kubectl exec "$pod_name" -n "$namespace" -- \
        iperf3 -c "$server_ip" -p "$port" -t 10 -u -b 20M -P 1 -B "$UE_IP" > "$tcp_log_filename" 2>&1 &
    pids="$pids $!"
    echo "iPerf3 PID for UE$j: $!"
  done
  wait $pids
  pids=""
  echo "_________________________________________"
  sleep 1

done
#kubectl exec ueransim-ue1-b5584d54c-w272k -n open5gs -- iperf3 -c 129.97.168.65 -t 30 -P 1 > ue1_log.txt 2>&1 & -u -b 1000000M
#-u -b 1000000M 
echo "All UEs deployed incrementally and tests initiated."
