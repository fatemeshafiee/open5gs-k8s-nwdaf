kubectl delete -k ueransim/ueransim-ue -n open5gs
kubectl delete -k ueransim/ueransim-gnb/ -n open5gs
kubectl delete -k open5gs -n open5gs
kubectl delete -k mongodb -n open5gs
kubectl delete -k NWDAF -n open5gs
kubectl delete -f test_upf/upf_subscriber_deployment.yaml  -n open5gs
kubectl delete -k NWDAF/MLflow/ -n open5gs
