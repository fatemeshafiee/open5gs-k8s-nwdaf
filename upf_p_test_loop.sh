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
  echo "Waiting for all pods in namespace '$namespace' to be removed..."
  while true; do
    local pods
    pods=$(kubectl get pods -n "$namespace" -o jsonpath='{.items[*].metadata.name}')
    if [ -z "$pods" ]; then
      echo "No pods remain in namespace '$namespace'."
      break
    else
      echo "Pods still present: $pods"
      sleep 5
    fi
  done
}

# Loop over different iperf bandwidth values (in M)
for M in 100; do
    echo "----------------------"
    echo "Starting experiment with iperf bandwidth: ${M}M"
    echo "----------------------"
    
    # Deploy core resources
    kubectl apply -k mongodb -n "$namespace"
    check_pods_running "app=mongodb"
    
    kubectl apply -k open5gs -n "$namespace"
    check_pods_running "app=open5gs"
    
    kubectl apply -k ueransim/ueransim-gnb/ -n "$namespace"
    check_pods_running "app=gnb"
    
    kubectl apply -k ueransim/ueransim-ue/ue1 -n "$namespace"
    check_pods_running "app=ueransim,component=ue,name=ue1"
    
    kubectl apply -k ueransim/ueransim-ue/ue2 -n "$namespace"
    check_pods_running "app=ueransim,component=ue,name=ue2"
    
    sleep 10
    mkdir -p "${directory_name}/experiment_${M}"
    
    # Deploy UPF subscriber and scale it redo for no subscriber no ees
    kubectl apply -f test_upf/upf_subscriber_deployment.yaml -n "$namespace"
    # kubectl scale deployment upf-subscriber --replicas=3 -n "$namespace"
    check_pods_running "upf-subscriber"
    sleep 10
    
    # UE1: Throughput test using iperf3
    ue_1=$(kubectl get pods -n "$namespace" -l "app=ueransim,component=ue,name=ue1" -o jsonpath='{.items[0].metadata.name}')
    if [ -z "$ue_1" ]; then
      echo "No pod found with label 'name=ue1'"
      exit 1
    fi
    echo "UE1 pod: $ue_1"
    
    INTERFACE="uesimtun0"
    UE_IP_1=$(kubectl exec "$ue_1" -n "$namespace" -- bash -c "ip -4 addr show $INTERFACE | grep -oP '(?<=inet\s)10\.42\.\d+\.\d+' | head -n 1")
    echo "Detected UE1 IP: $UE_IP_1"
    
    tcp_log_filename="${directory_name}/experiment_${M}/iperf3_from_ue1.log"
    kubectl exec "$ue_1" -n "$namespace" -- \
      iperf3 -c "$server_ip" -t 60 -u -b "${M}M" -B "$UE_IP_1" > "$tcp_log_filename" 2>&1 &
    iperf_pid=$!
    
    # UE2: Ping test
    ue_2=$(kubectl get pods -n "$namespace" -l "app=ueransim,component=ue,name=ue2" -o jsonpath='{.items[0].metadata.name}')
    UE_IP_2=$(kubectl exec "$ue_2" -n "$namespace" -- bash -c "ip -4 addr show $INTERFACE | grep -oP '(?<=inet\s)10\.42\.\d+\.\d+' | head -n 1")
    echo "Detected UE2 IP: $UE_IP_2"
    
    ping_log_filename="${directory_name}/experiment_${M}/ping_from_ue2.log"
    kubectl exec "$ue_2" -n "$namespace" -- \
      bash -c "ping -I $UE_IP_2 -i 1 -w 60 $server_ip" > "$ping_log_filename" 2>&1 &
    ping_pid=$!
    resource_log_filename="${directory_name}/experiment_${M}/upf_resource_usage.log"
    (
      for second in {1..240}; do
        echo "$(date +"%Y-%m-%d %H:%M:%S") - Monitoring cycle $second" >> "$resource_log_filename"
        kubectl top pod -n "$namespace" | grep "upf2" >> "$resource_log_filename"
        sleep 0.25
      done
    ) &
    monitor_pid=$!
    
    echo "Experiment with ${M}M bandwidth initiated."
    
    # Wait for experiment processes to finish
    wait $iperf_pid
    wait $ping_pid
    wait $monitor_pid
    echo "Experiment with ${M}M bandwidth completed."
    
    # Undeploy resources for the current experiment
    ./undeploy.sh
    wait_for_no_resources
    
    echo "Resources undeployed for experiment ${M}. Waiting before next iteration..."
    sleep 10
done

echo "All experiments completed."
