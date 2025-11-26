# Kafka on Kubernetes

## Overview

This project provides a production-ready Apache Kafka deployment on Kubernetes using the Strimzi operator. The setup includes a Kafka cluster with configurable brokers, persistent storage, and example producer/consumer applications for integration with NestJS microservices.

## Components

- Strimzi Kafka Operator for cluster management
- Kafka cluster running in KRaft mode (no ZooKeeper dependency)
- Persistent storage using local-path provisioner at /mnt/ssd/kafka
- Three topics: hospital, designation, department
- Producer and consumer FastAPI applications (deployment ready)
- GitLab CI/CD pipeline for automated deployment

## Prerequisites

#### Kubernetes Cluster
- K3s or any Kubernetes cluster (v1.24+)
- kubectl configured with cluster access
- Node with at least 8GB RAM, 4 vCPUs
- Storage available at /mnt/ssd/kafka on worker nodes

#### Software Requirements
- kubectl CLI tool
- Git for version control
- SSH access to Kubernetes nodes (for CI/CD)

## Architecture

#### Namespace
All components deploy to the k3s-kafka namespace.

#### Storage
- StorageClass: kafka-local-storage using local-path provisioner
- PersistentVolumes at /mnt/ssd/kafka/broker-N for each broker
- Retain policy ensures data persists across pod restarts

#### Kafka Cluster
- Development: 1 broker, 1 partition, 1 replica
- Production: 2+ brokers, 4+ partitions, 2+ replicas
- NodePort access on port 30092 for external connectivity
- Internal access via k3s-kafka-cluster-kafka-bootstrap:9092

#### Topics
- hospital: Hospital creation and update events
- designation: Designation management events
- department: Department management events
- All topics use 7-day retention and GZIP compression

## Directory Structure

```
k3s-kafka/
├── namespace/
│   └── namespace.yaml
├── storage/
│   ├── storage-class.yaml
│   └── pv-broker-0.yaml
├── strimzi/
│   ├── serviceaccount.yaml
│   ├── clusterrole.yaml
│   ├── clusterrolebinding.yaml
│   └── deployment.yaml
├── kafka/
│   ├── cluster.yaml
│   ├── topic-hospital.yaml
│   ├── topic-designation.yaml
│   └── topic-department.yaml
├── producer/
│   ├── configmap.yaml
│   ├── deployment.yaml
│   └── service.yaml
├── consumer/
│   ├── configmap.yaml
│   ├── deployment.yaml
│   └── service.yaml
├── setup.sh
├── deploy.sh
├── .gitlab-ci.yml
├── SCALING.md
└── NESTJS_USAGE.md
```

## Installation

#### Manual Deployment

1. Create storage directories on Kubernetes nodes:

```bash
bash setup.sh
```

2. Deploy all components:

```bash
bash deploy.sh
```

3. Verify deployment:

```bash
kubectl get pods -n k3s-kafka
kubectl get svc -n k3s-kafka
kubectl get kafkatopic -n k3s-kafka
```

#### GitLab CI/CD Deployment

The repository includes a GitLab CI pipeline that automatically deploys on push to master branch.

Required GitLab CI/CD variables:
- SSH_PRIVATE_KEY: SSH key for accessing K3s host
- K3S_HOST: Hostname or IP of Kubernetes server
- K3S_USER: SSH username for K3s host

The pipeline syncs files via rsync, runs setup if needed, and executes deployment.

## Configuration

#### Development Setup (Current)
- Brokers: 1
- Partitions: 1 per topic
- Replication: 1
- Storage: 50Gi per broker

#### Production Setup (Recommended)
- Brokers: 2+
- Partitions: 4+ per topic
- Replication: 2+
- Storage: 100Gi+ per broker

See SCALING.md for detailed scaling instructions.

## Accessing Kafka

#### From Outside Kubernetes

Using NodePort on port 30092:

```
KAFKA_BOOTSTRAP_SERVERS=<node-ip>:30092
```

Example:
```
KAFKA_BOOTSTRAP_SERVERS=192.168.1.100:30092
```

#### From Inside Kubernetes

Using internal service:

```
KAFKA_BOOTSTRAP_SERVERS=k3s-kafka-0.k3s-kafka-headless.k3s-kafka.svc.cluster.local:9092
```

## NestJS Integration

This Kafka deployment is designed for integration with NestJS microservices. See NESTJS_USAGE.md for complete integration guide including:

- Installing required packages
- Creating Kafka module and services
- Producer implementation for sending events
- Consumer implementation for receiving events
- Complete CRUD examples with database persistence

#### Quick Example

```typescript
// Send hospital event
await this.kafkaClient.emit('hospital', {
  key: hospitalId,
  value: {
    action: 'CREATE',
    data: hospitalData,
    timestamp: new Date().toISOString(),
  },
});
```

## Testing

#### Check Cluster Status

```bash
kubectl get kafka -n k3s-kafka
kubectl get pods -n k3s-kafka
```

#### List Topics

```bash
kubectl exec -n k3s-kafka k3s-kafka-0 -- \
  kafka-topics --list \
  --bootstrap-server localhost:9092
```

#### Send Test Message

```bash
kubectl exec -i -n k3s-kafka k3s-kafka-0 -- \
  kafka-console-producer \
  --topic hospital \
  --bootstrap-server localhost:9092
```

Type your message and press Enter.

#### Consume Messages

```bash
kubectl exec -n k3s-kafka k3s-kafka-0 -- \
  kafka-console-consumer \
  --topic hospital \
  --from-beginning \
  --bootstrap-server localhost:9092
```

## Scaling

The cluster can be scaled horizontally by adding brokers and increasing partition count. Key points:

- Each new broker requires a PersistentVolume
- Replication factor cannot exceed broker count
- Partitions can only increase, never decrease
- Kafka automatically rebalances partitions

See SCALING.md for step-by-step scaling guide.

## Application Endpoints

After deployment, applications are accessible via NodePort:

- Producer: http://<node-ip>:30801
- Consumer: http://<node-ip>:30802
- Kafka: <node-ip>:30092

Note: Producer and consumer deployments reference placeholder images. Update image references in deployment YAML files with your registry.

## Monitoring

#### Pod Logs

```bash
kubectl logs -n k3s-kafka <pod-name>
```

#### Kafka Broker Logs

```bash
kubectl logs -n k3s-kafka k3s-kafka-0
```

#### Consumer Group Status

```bash
kubectl exec -n k3s-kafka k3s-kafka-0 -- \
  kafka-consumer-groups \
  --bootstrap-server localhost:9092 \
  --group his-consumer-group \
  --describe
```

## Troubleshooting

#### Pods Not Starting

Check events and logs:
```bash
kubectl describe pod <pod-name> -n k3s-kafka
kubectl logs <pod-name> -n k3s-kafka
```

#### Storage Issues

Verify PV and PVC status:
```bash
kubectl get pv
kubectl get pvc -n k3s-kafka
```

Ensure storage directory exists on node:
```bash
ls -la /mnt/ssd/kafka/
```

#### Operator Not Running

Check Strimzi operator:
```bash
kubectl get deployment strimzi-cluster-operator -n k3s-kafka
kubectl logs deployment/strimzi-cluster-operator -n k3s-kafka
```

#### Topic Not Created

Verify Kafka cluster is ready:
```bash
kubectl get kafka k3s-kafka-cluster -n k3s-kafka
```

Check topic status:
```bash
kubectl get kafkatopic -n k3s-kafka
kubectl describe kafkatopic hospital -n k3s-kafka
```

## Cleanup

Remove all Kafka resources:

```bash
kubectl delete namespace k3s-kafka
```

Note: This does not delete PersistentVolumes. To remove data:

```bash
kubectl delete pv kafka-broker-0-pv
sudo rm -rf /mnt/ssd/kafka
```

## License

This project is part of the Hospital Information System deployment.
