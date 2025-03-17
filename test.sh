#!/bin/bash

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <directory_name>"
  exit 1
fi

directory_name=$1

check_pods_running() {
  namespace=$1
  label=$2
  echo "Checking if all pods with label $label in namespace '$namespace' are running..."
  while true; do
    # Get the status of all pods with the specific label, filtering out those that are not running.
    non_running_pods=$(kubectl get pods -l $label -n "$namespace" --field-selector=status.phase!=Running -o jsonpath='{.items[*].metadata.name}')
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

kubectl apply -k mongodb -n open5gs
check_pods_running "open5gs" "app=mongodb"

kubectl apply -k open5gs -n open5gs
check_pods_running "open5gs" "app=open5gs"

kubectl apply -k NWDAF -n open5gs
check_pods_running "open5gs" "app=nwdaf-sbi"

sleep 60
kubectl apply -k ueransim/ueransim-gnb/ -n open5gs
check_pods_running "open5gs" "app=gnb"


for i in $(seq 1 10); do 
  dir_name="${directory_name}-rusage"
  mkdir -p "$dir_name"

 
  kubectl apply -k ueransim/ueransim-ue/ue$i -n open5gs
  check_pods_running "open5gs" "app=ue$i"

  # Construct log file name based on the directory name and number of UEs
  log_filename="${dir_name}-UE-${i}.log"

  cd "$dir_name"
  echo "Monitoring CPU and Memory usage for 60 seconds after deploying UE$i..."
  for second in {1..60}; do
    echo "$(date +"%Y-%m-%d %H:%M:%S") - Monitoring cycle $second" >> "$log_filename"
    kubectl top pod -n open5gs | grep "upf2\|nwdaf-sbi" >> "$log_filename"
    echo "--------------------------------------------" >> "$log_filename"
    sleep 1
  done

  # Return to the base directory
  cd ..
done

echo "All UEs deployed incrementally."
