#!/bin/bash
set -e
echo "Setting up Kafka storage..."
NODE_NAME=$(kubectl get nodes -o jsonpath='{.items[0].metadata.name}')
echo "Target node: $NODE_NAME"
kubectl debug node/$NODE_NAME -it --image=busybox -- sh -c "
  mkdir -p /host/mnt/ssd/kafka/broker-0
  chmod -R 755 /host/mnt/ssd/kafka
  chown -R 1000:1000 /host/mnt/ssd/kafka
"
echo "Storage directories created at /mnt/ssd/kafka/broker-0"
