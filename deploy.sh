set -e

echo "Deploying Kafka to his-kafka namespace..."

echo "Creating namespace..."
kubectl apply -f namespace/

echo "Setting up storage..."
kubectl apply -f storage/

echo "Installing Strimzi operator and CRDs..."
kubectl apply -f strimzi-operator.yaml
echo "Waiting for operator..."
kubectl wait deployment/strimzi-cluster-operator \
  --for=condition=Available \
  --timeout=300s \
  -n his-kafka

echo "Deploying Kafka cluster..."
kubectl apply -f kafka/cluster.yaml
echo "Waiting for Kafka cluster..."
kubectl wait kafka/his-kafka-cluster \
  --for=condition=Ready \
  --timeout=600s \
  -n his-kafka

echo "Creating topics..."
kubectl apply -f kafka/topic-hospital.yaml
kubectl apply -f kafka/topic-designation.yaml
kubectl apply -f kafka/topic-department.yaml

echo "Waiting for topics..."
sleep 10
kubectl wait kafkatopic/hospital --for=condition=Ready --timeout=60s -n his-kafka
kubectl wait kafkatopic/designation --for=condition=Ready --timeout=60s -n his-kafka
kubectl wait kafkatopic/department --for=condition=Ready --timeout=60s -n his-kafka

echo "Deploying producer and consumer..."
kubectl apply -f producer/
kubectl apply -f consumer/

echo ""
echo "Deployment complete"
echo ""
kubectl get pods -n his-kafka
echo ""
kubectl get svc -n his-kafka
echo ""
echo "Kafka cluster ready"
echo "Producer: http://<node-ip>:30801"
echo "Consumer: http://<node-ip>:30802"
echo "Kafka: <node-ip>:30092"
