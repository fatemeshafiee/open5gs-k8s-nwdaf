#!/bin/bash

# This script manages k8s resources in the open5gs namespace.
# Supported commands:
#   delete [name]  - Deletes resources using kustomize: kubectl delete -k [name] -n open5gs
#   apply [name]   - Applies resources using kustomize: kubectl apply -k [name] -n open5gs
#   logs [name]    - Shows logs for pods matching [name] in the open5gs namespace
#   exec [name]    - Opens an interactive bash session in pods matching [name] in the open5gs namespace
#
# To exit the script, press Ctrl+C.

while true; do
    read -p "Enter command (<delete|apply|logs|exec> [name]): " action name

    if [[ -z "$action" || -z "$name" ]]; then
        echo "Usage: <delete|apply|logs|exec> [name]"
        continue
    fi

    case "$action" in
        delete)
            echo "Executing: kubectl delete -k $name -n open5gs"
            kubectl delete -k "$name" -n open5gs
            ;;
        apply)
            echo "Executing: kubectl apply -k $name -n open5gs"
            kubectl apply -k "$name" -n open5gs
            ;;
        logs)
            pods=$(kubectl get pods -n open5gs --no-headers -o custom-columns=":metadata.name" | grep "$name")
            if [[ -z "$pods" ]]; then
                echo "No pods found matching '$name' in the open5gs namespace."
                continue
            fi
            echo "Found pod(s):"
            echo "$pods"
            for pod in $pods; do
                echo "Logs for pod: $pod"
                kubectl logs "$pod" -n open5gs
            done
            ;;
        exec)
            pods=$(kubectl get pods -n open5gs --no-headers -o custom-columns=":metadata.name" | grep "$name")
            if [[ -z "$pods" ]]; then
                echo "No pods found matching '$name' in the open5gs namespace."
                continue
            fi
            echo "Found pod(s):"
            echo "$pods"
            for pod in $pods; do
                echo "Opening interactive bash shell for pod: $pod"
                kubectl exec -it "$pod" -n open5gs -- /bin/bash
            done
            ;;
        *)
            echo "Invalid command: $action"
            echo "Allowed commands: delete, apply, logs, exec"
            ;;
    esac

    echo "-------------------------------"
done
