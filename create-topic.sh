#!/bin/bash

if [ -z "$1" ]; then
  echo "Usage: ./create-topic.sh <topic-name> [partitions]"
  echo "Example: ./create-topic.sh hospital 3"
  exit 1
fi

TOPIC=$1
PARTITIONS=3

echo "Creating topic '$TOPIC' with $PARTITIONS partitions..."

kubectl exec -n k3s-kafka k3s-kafka-0 -- kafka-topics --create \
  --bootstrap-server localhost:9092 \
  --topic $TOPIC \
  --partitions $PARTITIONS \
  --replication-factor 1 \
  --config retention.ms=604800000 \
  --config compression.type=gzip \
  --if-not-exists

echo "✅ Topic '$TOPIC' created successfully!"
echo "Current topics:"
kubectl exec -n k3s-kafka k3s-kafka-0 -- kafka-topics --bootstrap-server localhost:9092 --list
