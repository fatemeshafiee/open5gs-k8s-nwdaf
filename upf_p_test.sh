#!/bin/bash

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <directory_name>"
  exit 1
fi

directory_name=$1
namespace="open5gs"
server_ip="129.97.168.51"

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

kubectl apply -k ueransim/ueransim-gnb/ -n $namespace
check_pods_running "app=gnb"

kubectl apply -k ueransim/ueransim-ue/ue1 -n $namespace
check_pods_running "app=ueransim,component=ue,name=ue1"
kubectl apply -k ueransim/ueransim-ue/ue2 -n $namespace
check_pods_running "app=ueransim,component=ue,name=ue2"

sleep 10
mkdir -p "${directory_name}"
# Resource monitoring for UPF
resource_log_filename="${directory_name}/upf_resource_usage.log"
for second in {1..150}; do
  echo "$(date +"%Y-%m-%d %H:%M:%S") - Monitoring cycle $second" >> "$resource_log_filename"
  kubectl top pod -n $namespace | grep "upf" >> "$resource_log_filename"
  sleep 0.5
done &

kubectl apply -f test_upf/upf_subscriber_deployment.yaml  -n open5gs
kubectl scale deployment upf-subscriber --replicas=3 -n open5gs
check_pods_running "upf-subscriber"

sleep 10

# UE1: Throughput test
ue_1=$(kubectl get pods -n $namespace -l "app=ueransim,component=ue,name=ue1" -o jsonpath='{.items[0].metadata.name}')
echo "Pod name found: '$ue_1'"
if [ -z "$ue_1" ]; then
  echo "No pod found with 'name=ue1'"
  exit 1
fi

INTERFACE="uesimtun0"
UE_IP_1=$(kubectl exec "$ue_1" -n "$namespace" -- bash -c \
  "ip -4 addr show $INTERFACE | grep -oP '(?<=inet\s)10\.42\.\d+\.\d+' | head -n 1")
echo "Detected UE 1 IP from the UPF container: $UE_IP_1"

tcp_log_filename="${directory_name}/iperf3_from_ue1.log"
kubectl exec "$ue_1" -n "$namespace" -- \
  iperf3 -c "$server_ip" -t 300 -u -b 12M -B "$UE_IP_1" > "$tcp_log_filename" 2>&1 &
pids="$pids $!"

# UE2: Ping test
ue_2=$(kubectl get pods -n $namespace -l "app=ueransim,component=ue,name=ue2" -o jsonpath='{.items[0].metadata.name}')
UE_IP_2=$(kubectl exec "$ue_2" -n "$namespace" -- bash -c \
  "ip -4 addr show $INTERFACE | grep -oP '(?<=inet\s)10\.42\.\d+\.\d+' | head -n 1")
echo "Detected UE 2 IP from the UPF container: $UE_IP_2" 

ping_log_filename="${directory_name}/ping_from_ue2.log"
kubectl exec "$ue_2" -n "$namespace" -- \
  bash -c "ping -I $UE_IP_2 -i 1 -w 300 $server_ip" > "$ping_log_filename" 2>&1 &
pids="$pids $!"

echo "All UEs deployed incrementally and tests initiated."

# Wait for background processes (iperf3, ping, monitoring)
wait $pids
echo "All background tests and monitoring completed."