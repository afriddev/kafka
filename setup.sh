#!/bin/bash
set -e

echo "---- Setting up Host Storage ----"

# Get the first node name
NODE_NAME=$(kubectl get nodes -o jsonpath='{.items[0].metadata.name}')
echo "Target Node: $NODE_NAME"

# Create directory and set permissions using kubectl debug
# We mount /mnt/ssd on the host to /host/mnt/ssd in the debug container
# UID 1000 is standard for Confluent Kafka images
echo "Creating directories and setting permissions..."

# Note: This command assumes the debug container has access to the host filesystem at /host
# and that /mnt/ssd exists on the host.
kubectl debug node/$NODE_NAME -it --image=busybox --profile=sysadmin -- \
  sh -c "mkdir -p /host/mnt/ssd/kafka/broker-0 && \
         chown -R 1000:1000 /host/mnt/ssd/kafka/broker-0 && \
         chmod -R 755 /host/mnt/ssd/kafka/broker-0"

echo "Storage directory created and permissions set at /mnt/ssd/kafka/broker-0"
echo "---- Setup Complete ----"
