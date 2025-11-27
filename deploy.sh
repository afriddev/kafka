#!/bin/bash
set -e

echo "---- Deploying Kafka Project ----"

# 1. Namespace
echo "Applying Namespace..."
kubectl apply -f namespace/namespace.yaml

# 2. Storage
echo "Applying Storage..."
kubectl apply -f storage/kafka-storageclass.yaml
kubectl apply -f storage/pv/kafka-pv-0.yaml

# 3. ConfigMaps
echo "Applying ConfigMaps..."
kubectl apply -f configmaps/kafka-configmap.yaml

# 4. Services
echo "Applying Services..."
kubectl apply -f services/headless/kafka-headless.yaml
kubectl apply -f services/nodeport/kafka-nodeport.yaml

# 5. Workloads
echo "Applying Workloads..."
kubectl apply -f statefulsets/kafka-statefulset.yaml

# Validation
echo "Waiting for Pods to be ready..."
kubectl wait --namespace k3s-kafka \
  --for=condition=ready pod \
  --selector=app=kafka \
  --timeout=300s

# Output
NODE_IP=$(kubectl get node -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
NODE_PORT=30092

echo "---- Deployment Complete ----"
echo "Kafka External Access: $NODE_IP:$NODE_PORT"
echo "Internal Headless: k3s-kafka-0.k3s-kafka-headless.k3s-kafka.svc.cluster.local:9092"
