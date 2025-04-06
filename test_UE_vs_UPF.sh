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

# Loop over different numbers of UEs from 1 to 10
for num_ues in 3 7; do
    echo "----------------------"
    echo "Starting experiment with ${num_ues} UE(s) (Total throughput fixed at 10 Mbit)"
    echo "----------------------"
    
    # Deploy core resources
    kubectl apply -k mongodb -n "$namespace"
    check_pods_running "app=mongodb"
    
    kubectl apply -k open5gs -n "$namespace"
    check_pods_running "app=open5gs"
    
    kubectl apply -k ueransim/ueransim-gnb/ -n "$namespace"
    check_pods_running "app=gnb"
    
    # Deploy UE pods dynamically (ue1, ue2, ..., ue$num_ues)
    for (( i=1; i<=num_ues; i++ )); do
         kubectl apply -k ueransim/ueransim-ue/ue$i -n "$namespace"
         check_pods_running "app=ueransim,component=ue,name=ue$i"
    done

    sleep 10
    mkdir -p "${directory_name}/experiment_${num_ues}"
    
    # Deploy UPF subscriber
    kubectl apply -f test_upf/upf_subscriber_deployment.yaml -n "$namespace"
    check_pods_running "upf-subscriber"
    sleep 10
    
    # Compute throughput per UE so that overall throughput equals 10 Mbit.
    throughput_per_ue=$(echo "scale=2; 10/$num_ues" | bc)
    echo "Each UE will send at ${throughput_per_ue} Mbit."
    
    # Start iperf3 tests on each UE
    iperf_pids=()
    INTERFACE="uesimtun0"
    
for (( i=1; i<=num_ues; i++ )); do
     ue_pod=$(kubectl get pods -n "$namespace" -l "app=ueransim,component=ue,name=ue$i" -o jsonpath='{.items[0].metadata.name}')
     if [ -z "$ue_pod" ]; then
          echo "No pod found with label 'name=ue$i'"
          exit 1
     fi
     echo "UE${i} pod: $ue_pod"
     
     ue_ip=$(kubectl exec "$ue_pod" -n "$namespace" -- bash -c "ip -4 addr show $INTERFACE | grep -oP '(?<=inet\s)10\.42\.\d+\.\d+' | head -n 1")
     echo "Detected UE${i} IP: $ue_ip"
     
     iperf_log_filename="${directory_name}/experiment_${num_ues}/iperf3_from_ue${i}.log"
     
     # Calculate the server port for this UE (mapping UE number to port)
     port=$((5000 + i))
     echo "Using server port: $port for UE${i}"
     
     # Run iperf3 with the calculated port
     kubectl exec "$ue_pod" -n "$namespace" -- \
        iperf3 -c "$server_ip" -p "$port" -t 60 -u -b "${throughput_per_ue}M" -B "$ue_ip" > "$iperf_log_filename" 2>&1 &
     iperf_pids+=($!)
done


    # Monitor UPF CPU usage every 0.5 sec for 60 sec (120 cycles)
    resource_log_filename="${directory_name}/experiment_${num_ues}/upf_resource_usage.log"
    (
      for (( cycle=1; cycle<=120; cycle++ )); do
          echo "$(date +"%Y-%m-%d %H:%M:%S") - Monitoring cycle $cycle" >> "$resource_log_filename"
          kubectl top pod -n "$namespace" | grep "upf2" >> "$resource_log_filename"
          sleep 0.5
      done
    ) &
    monitor_pid=$!
    
    # Wait for all iperf3 processes to finish
    for pid in "${iperf_pids[@]}"; do
         wait $pid
    done

    wait $monitor_pid
    echo "Experiment with ${num_ues} UE(s) completed."
    
    # Undeploy resources for the current experiment
    ./undeploy.sh
    wait_for_no_resources
    
    echo "Resources undeployed for experiment with ${num_ues} UE(s). Waiting before next iteration..."
    sleep 10
done

echo "All experiments completed."
