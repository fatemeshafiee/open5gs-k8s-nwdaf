#!/bin/bash

# Function to wait for user input to proceed
wait_for_keypress() {
  echo "Press any key to proceed to the next step..."
  while [ true ]; do
    read -t 3 -n 1
    if [ $? = 0 ]; then
      break
    fi
  done
}

# Function to run setup commands
run_setup() {
  echo "🔧 Starting setup process..."

  setup_commands=(
    "cd /home/f2shafie/testbed-automator"
    "./uninstall.sh"
    "./install.sh"
    "cd /home/f2shafie/open5gs-k8s"
    "kubectl create namespace open5gs"
  )

  for cmd in "${setup_commands[@]}"; do
    echo "🚀 Executing: $cmd"
    eval $cmd
    if [ $? -ne 0 ]; then
      echo "❌ Error executing: $cmd"
      exit 1
    fi
  done

  # Apply MongoDB and wait for user input before proceeding
  echo "🚀 Applying MongoDB configuration..."
  kubectl apply -k mongodb -n open5gs
  if [ $? -ne 0 ]; then
    echo "❌ Error applying MongoDB"
    exit 1
  fi

  echo "📡 Watching MongoDB pods in 'open5gs' namespace..."
  kubectl get pods -n open5gs --watch &
  WATCH_PID=$!
  wait_for_keypress
  kill $WATCH_PID

  # Continue with the remaining setup steps
  remaining_commands=(
    "kubectl apply -k networks5g -n open5gs"
    "source venv/bin/activate"
    "python mongo-tools/generate-data.py"
    "python mongo-tools/delete-subscribers.py"
    "python mongo-tools/add-subscribers.py"
  )

  for cmd in "${remaining_commands[@]}"; do
    echo "🚀 Executing: $cmd"
    eval $cmd
    if [ $? -ne 0 ]; then
      echo "❌ Error executing: $cmd"
      exit 1
    fi
  done

  echo "✅ Setup process completed successfully."
}

# Function to deploy services
deploy_services() {
  deployments=(
    "kubectl apply -k open5gs -n open5gs"
    "kubectl apply -k NWDAF -n open5gs"
    "./integrate_profile.sh"
  )

  for deploy in "${deployments[@]}"; do
    echo "🚀 Running: $deploy"
    eval $deploy
    if [ $? -ne 0 ]; then
      echo "❌ Deployment failed: $deploy"
      exit 1
    fi

    echo "📡 Watching pods in namespace 'open5gs'..."
    kubectl get pods -n open5gs --watch &
    WATCH_PID=$!
    wait_for_keypress
    kill $WATCH_PID
  done

  echo "✅ All deployments completed successfully."
}

# Run setup before deploying
run_setup
deploy_services
