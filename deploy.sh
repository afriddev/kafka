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

# Create topics using kafka-topics.sh
for topic in hospital designation department; do
  kubectl exec -n his-kafka his-kafka-0 -- kafka-topics --create \
    --bootstrap-server localhost:9092 \
    --topic $topic \
    --partitions 1 \
    --replication-factor 1 \
    --config compression.type=gzip \
    --config retention.ms=604800000 \
    --if-not-exists
done

echo "Deploying producer and consumer..."
kubectl apply -f producer/
kubectl apply -f consumer/

echo ""
echo "Deployment complete!"
echo ""
kubectl get pods -n his-kafka
echo "Kafka cluster ready!"
echo "Bootstrap server: <node-ip>:30092"
