# Kafka Scaling Guide
## Current Development Setup

- Brokers: 1
- Partitions per topic: 1
- Replication factor: 1
- PVCs: 1 (broker-0 only)
- Storage: /mnt/ssd/kafka/broker-0 (50Gi)
- Topics: hospital, designation, department

## Understanding Kafka Scaling

#### Adding Brokers

- New PVC Required: Yes, each broker needs its own PVC
- Storage Directory: Create /mnt/ssd/kafka/broker-N on the node
- Kafka Auto-Rebalances: Partitions redistribute across brokers
- Zero Downtime: Kafka stays online during scaling

#### Adding Partitions

- No New PVC: Existing PVCs expand to hold new partitions
- Kafka Redistributes: New partitions spread across all brokers
- Cannot Decrease: Partition count can only increase, never decrease

#### Replication Factor

- Rule: replicas must be less than or equal to number of brokers
- Example: 2 brokers means max 2 replicas per partition
- Purpose: Each replica stored on different broker for high availability

## Scaling to 2 Brokers

#### Why Scale to 2 Brokers

- High Availability: If broker-0 crashes, broker-1 takes over
- Load Balancing: Distribute read/write across multiple servers
- Data Redundancy: Each partition replicated on both brokers

#### Requirements

- New PVC for broker-1
- New Storage Directory: /mnt/ssd/kafka/broker-1
- Update Cluster Config: Change replicas to 2
- Update Topics: Change replicas to 2

#### Create Storage for Broker-1

Get node name and create storage directory:

```bash
NODE_NAME=$(kubectl get nodes -o jsonpath='{.items[0].metadata.name}')
echo "Node: $NODE_NAME"

kubectl debug node/$NODE_NAME -it --image=busybox -- sh -c "
  mkdir -p /host/mnt/ssd/kafka/broker-1
  chmod -R 755 /host/mnt/ssd/kafka/broker-1
  chown -R 1000:1000 /host/mnt/ssd/kafka/broker-1
"
```

Create PersistentVolume file storage/pv-broker-1.yaml:

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: kafka-broker-1-pv
  labels:
    type: local
    broker-id: "1"
spec:
  storageClassName: kafka-local-storage
  capacity:
    storage: 50Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  hostPath:
    path: /mnt/ssd/kafka/broker-1
    type: DirectoryOrCreate
```

Apply the PV:

```bash
kubectl apply -f storage/pv-broker-1.yaml
kubectl get pv kafka-broker-1-pv
```

#### Scale Kafka Cluster to 2 Brokers

Edit kafka/cluster.yaml and change:

```yaml
spec:
  kafka:
    replicas: 2
    config:
      default.replication.factor: 2
      offsets.topic.replication.factor: 2
      transaction.state.log.replication.factor: 2
```

Apply the changes:

```bash
kubectl apply -f kafka/cluster.yaml
kubectl get pods -n his-kafka -w
kubectl wait kafka/his-kafka-cluster --for=condition=Ready --timeout=600s -n his-kafka
```

Verify the deployment:

```bash
kubectl get pods -n his-kafka | grep kafka
kubectl get pvc -n his-kafka
```

#### Update Existing Topics to Replicate

Edit kafka/topic-hospital.yaml:

```yaml
spec:
  partitions: 1
  replicas: 2
```

Apply and verify:

```bash
kubectl apply -f kafka/topic-hospital.yaml
kubectl wait kafkatopic/hospital --for=condition=Ready --timeout=60s -n his-kafka
```

Do the same for designation and department topics.

Verify replication:

```bash
kubectl exec -n his-kafka his-kafka-cluster-kafka-0 -- \
  /opt/kafka/bin/kafka-topics.sh --describe --topic hospital \
  --bootstrap-server localhost:9092
```

Expected output shows Leader, Replicas, and Isr (in-sync replicas).

## Increasing Partitions to 4

#### Why More Partitions

- Higher Throughput: 4 partitions means 4x parallel writes
- Better Load Distribution: Spread across 2 brokers (2 partitions each)
- More Consumers: Can run 4 consumers in parallel

#### Update Topic Partitions

Edit kafka/topic-hospital.yaml:

```yaml
spec:
  partitions: 4
  replicas: 2
```

Apply changes:

```bash
kubectl apply -f kafka/topic-hospital.yaml
kubectl apply -f kafka/topic-designation.yaml
kubectl apply -f kafka/topic-department.yaml
```

Verify partition distribution:

```bash
kubectl exec -n his-kafka his-kafka-cluster-kafka-0 -- \
  /opt/kafka/bin/kafka-topics.sh --describe --topic hospital \
  --bootstrap-server localhost:9092
```

Check storage usage:

```bash
kubectl exec -n his-kafka his-kafka-cluster-kafka-0 -- \
  du -sh /var/lib/kafka/data/hospital-*

kubectl exec -n his-kafka his-kafka-cluster-kafka-1 -- \
  du -sh /var/lib/kafka/data/hospital-*
```

## Adding New Topics

Create kafka/topic-newname.yaml:

```yaml
apiVersion: kafka.strimzi.io/v1beta2
kind: KafkaTopic
metadata:
  name: newname
  namespace: his-kafka
  labels:
    strimzi.io/cluster: his-kafka-cluster
spec:
  partitions: 4
  replicas: 2
  config:
    retention.ms: 604800000
    segment.bytes: 536870912
    compression.type: gzip
```

Apply:

```bash
kubectl apply -f kafka/topic-newname.yaml
kubectl wait kafkatopic/newname --for=condition=Ready --timeout=60s -n his-kafka
```

## Scaling Requirements Summary

| Action         | New PVC | New Storage Dir | Update Cluster | Update Topics      |
| -------------- | ------- | --------------- | -------------- | ------------------ |
| Add Broker     | Yes     | Yes             | Yes            | Yes (for replicas) |
| Add Partitions | No      | No              | No             | Yes                |
| Add Topic      | No      | No              | No             | Yes (new file)     |

## Configuration Reference

| Setting             | Development | Production          |
| ------------------- | ----------- | ------------------- |
| Brokers             | 1           | 2+                  |
| Partitions          | 1           | 4+                  |
| Replicas            | 1           | 2+                  |
| PVCs                | 1           | 2+ (one per broker) |
| Storage             | 50Gi        | 100Gi+ per broker   |
| min.insync.replicas | 1           | 1                   |

## Important Rules

- Replicas cannot exceed number of brokers
- Partitions can only increase, never decrease
- Each broker needs dedicated PVC and storage
- Data persists even if pods are deleted (Retain policy)
