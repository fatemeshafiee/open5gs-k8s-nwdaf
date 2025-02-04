#!/bin/bash

# Function to wait for user input to proceed
wait_for_keypress() {
  echo "Press any key to proceed to the next deployment..."
  while [ true ] ; do
    read -t 3 -n 1
    if [ $? = 0 ] ; then
      break
    fi
  done
}

# Deployments
deployments=(
  "kubectl apply -k mongodb -n open5gs"
  "kubectl apply -k open5gs -n open5gs"
  "kubectl apply -k NWDAF -n open5gs"
)

# Loop through deployments
for deploy in "${deployments[@]}"; do
  echo "Running: $deploy"
  eval $deploy
  echo "Watching pods in namespace 'open5gs'..."
  kubectl get pods -n open5gs --watch &
  WATCH_PID=$!
  wait_for_keypress
  kill $WATCH_PID
done

echo "All deployments completed."

