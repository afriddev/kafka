set -e

echo "Deploying Kafka to his-kafka namespace..."

echo "Creating namespace..."
kubectl apply -f namespace/

echo "Setting up storage..."
kubectl apply -f storage/

echo "Deploying Kafka StatefulSet..."
kubectl apply -f kafka/kafka-config.yaml
kubectl apply -f kafka/kafka-service.yaml
kubectl apply -f kafka/kafka-statefulset.yaml

echo "Waiting for Kafka to be ready..."
kubectl wait statefulset/his-kafka \
  --for=jsonpath='{.status.readyReplicas}'=1 \
  --timeout=600s \
  -n his-kafka

echo "Creating topics..."
sleep 10

# Create topics using declarative YAML manifests
# Using 3 partitions for parallel processing and better throughput
kubectl apply -f kafka/topic-hospital.yaml
kubectl apply -f kafka/topic-department.yaml
kubectl apply -f kafka/topic-designation.yaml

# Wait for topic creation jobs to complete
echo "Waiting for topic creation to complete..."
kubectl wait --for=condition=complete --timeout=60s job/create-topic-hospital -n his-kafka
kubectl wait --for=condition=complete --timeout=60s job/create-topic-department -n his-kafka
kubectl wait --for=condition=complete --timeout=60s job/create-topic-designation -n his-kafka

# Verify topics were created
echo "Verifying topics..."
kubectl exec -n his-kafka his-kafka-0 -- kafka-topics --bootstrap-server localhost:9092 --list

echo "Deploying producer and consumer..."
kubectl apply -f producer/
kubectl apply -f consumer/

echo ""
echo "Deployment complete!"
echo ""
kubectl get pods -n his-kafka
echo "Kafka cluster ready!"
echo "Bootstrap server: <node-ip>:30092"
