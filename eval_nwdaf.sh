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

  mkdir -p "${directory_name}/experiment_${U}"
  resource_log_filename="${directory_name}/experiment_${U}/resource_usage.log"
  log_dir="${directory_name}/experiment_${U}/logs"
  mkdir -p "$log_dir"

  # Start resource monitoring (background)
  (
    for second in {1..240}; do
      echo "$(date +"%Y-%m-%d %H:%M:%S") - Monitoring cycle $second" >> "$resource_log_filename"
      kubectl top pod -n "$namespace" | grep -E "mlflow|nwdaf-database|nwdaf-engine|nwdaf-nbi-events|nwdaf-sbi|nbi-gateway|upf|smf" >> "$resource_log_filename"
      sleep 0.5
    done
  ) &
  monitor_pid=$!
  wait $monitor_pid
  
  ./undeploy.sh

  echo "Resources undeployed for experiment ${U}. Waiting before next iteration..."
  sleep 10
done

echo "🎉 All experiments completed."
