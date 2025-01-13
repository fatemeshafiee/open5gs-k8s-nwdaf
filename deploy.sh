kubectl apply -k mongodb -n open5gs
kubectl apply -k open5gs -n open5gs
sleep 60
kubectl apply -k NWDAF -n open5gs
kubectl apply -k ueransim/ueransim-gnb/ -n open5gs
sleep 30
kubectl apply -k ueransim/ueransim-ue -n open5gs
