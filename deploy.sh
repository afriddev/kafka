set -e

echo "Deploying Kafka to k3s-kafka namespace..."

echo "Creating namespace..."
kubectl apply -f namespace/

echo "Setting up storage..."
kubectl apply -f storage/

echo "Deploying Kafka StatefulSet..."
kubectl apply -f kafka/kafka-config.yaml
kubectl apply -f kafka/kafka-service.yaml
kubectl apply -f kafka/kafka-statefulset.yaml

echo "Waiting for Kafka to be ready..."
kubectl wait statefulset/k3s-kafka \
  --for=jsonpath='{.status.readyReplicas}'=1 \
  --timeout=600s \
  -n k3s-kafka

echo ""
echo "Deployment complete!"
echo ""
kubectl get pods -n k3s-kafka
echo "Kafka cluster ready!"
echo "Bootstrap server: <node-ip>:30092"
