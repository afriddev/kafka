# Kafka on Kubernetes

## Overview
Production-ready Apache Kafka deployment on Kubernetes (K3s) using KRaft mode. This setup uses static provisioning with hostPath storage at `/mnt/ssd/` for persistent data.

----

## Quick Start

#### 1. Setup Host Storage
Prepare storage directories on the Kubernetes node:
```bash
bash setup.sh
```

#### 2. Deploy Kafka Cluster
Deploy all components in the correct order:
```bash
bash deploy.sh
```

#### 3. Verify Deployment
Check pod status:
```bash
kubectl get pods -n k3s-kafka
kubectl get svc -n k3s-kafka
```

----

## Project Structure

```
kafka/
├── configmaps/           # Kafka configuration files
├── statefulsets/         # Kafka broker StatefulSet
├── services/             # Service definitions
│   ├── headless/         # Internal pod discovery
│   └── nodeport/         # External access
├── storage/              # Storage configuration
│   ├── pv/               # PersistentVolume definitions
│   └── kafka-storageclass.yaml
├── namespace/            # Namespace definition
├── docs/                 # Documentation
└── setup.sh, deploy.sh   # Deployment scripts
```

#### Directory Details
- [configmaps/readme.md](configmaps/readme.md) - Configuration management
- [statefulsets/readme.md](statefulsets/readme.md) - Kafka broker workloads
- [services/readme.md](services/readme.md) - Service definitions
- [services/headless/readme.md](services/headless/readme.md) - Pod discovery service
- [services/nodeport/readme.md](services/nodeport/readme.md) - External access service
- [storage/readme.md](storage/readme.md) - Storage architecture
- [storage/pv/readme.md](storage/pv/readme.md) - PersistentVolume details
- [namespace/readme.md](namespace/readme.md) - Namespace configuration

----

## Documentation

#### Deployment & Operations
- [Deployment Guide](docs/deployment.md) - Step-by-step deployment instructions
- [Storage Architecture](docs/storage.md) - Storage design and backup procedures
- [Scaling Guide](docs/scaling.md) - How to scale from 1 to 3+ brokers

#### Usage & Integration
- [Usage Guide](docs/usage.md) - Basic usage and testing
- [NestJS Integration Guide](docs/nestjs-usage.md) - Complete NestJS integration examples
- [Production Resources](docs/production-resources.md) - Resource planning for production

----

## Architecture

#### Namespace
- `k3s-kafka` - All resources are deployed in this namespace

#### Storage
- **Type**: HostPath (Local Storage)
- **Path**: `/mnt/ssd/kafka/broker-N`
- **Class**: `kafka-local-storage` (Static Provisioning)
- **Policy**: Retain (data persists after pod deletion)

#### Services
- **Headless Service**: `k3s-kafka-headless` - Internal pod discovery for StatefulSet
- **NodePort Service**: `k3s-kafka-external` - External access on port `30092`

#### Kafka Cluster
- **Mode**: KRaft (No ZooKeeper)
- **Image**: `confluentinc/cp-kafka:7.8.0`
- **Replicas**: 1 (Development) - Scalable to 3+ (Production)
- **Resources**: 2Gi RAM, 500m-1000m CPU per broker

----

## Accessing Kafka

#### From Outside Kubernetes
```bash
# Using NodePort
KAFKA_BOOTSTRAP_SERVERS=<node-ip>:30092

# Example
KAFKA_BOOTSTRAP_SERVERS=192.168.1.100:30092
```

#### From Inside Kubernetes
```bash
# Using internal service
KAFKA_BOOTSTRAP_SERVERS=k3s-kafka-0.k3s-kafka-headless.k3s-kafka.svc.cluster.local:9092
```

----

## Testing

#### List Topics
```bash
kubectl exec -n k3s-kafka k3s-kafka-0 -- \
  kafka-topics --list \
  --bootstrap-server localhost:9092
```

#### Produce Message
```bash
kubectl exec -i -n k3s-kafka k3s-kafka-0 -- \
  kafka-console-producer \
  --topic test-topic \
  --bootstrap-server localhost:9092
```

#### Consume Messages
```bash
kubectl exec -n k3s-kafka k3s-kafka-0 -- \
  kafka-console-consumer \
  --topic test-topic \
  --from-beginning \
  --bootstrap-server localhost:9092
```

----

## Cleanup

Remove all resources:
```bash
kubectl delete namespace k3s-kafka
```

Remove persistent data (if needed):
```bash
kubectl delete pv kafka-broker-0-pv
# On the node:
sudo rm -rf /mnt/ssd/kafka
```
