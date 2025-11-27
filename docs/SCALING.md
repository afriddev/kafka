## Scaling Kafka Guide

This guide explains how to scale your Kafka cluster from 1 broker to 3 brokers.

----

#### 1. Create New Storage Directories (setup.sh)

You need to create storage folders for the new brokers. **Do not touch the existing broker-0 folder.**

Update your `setup.sh` to include the new folders:

```bash
# Existing broker-0 (Do not remove)
mkdir -p /host/mnt/ssd/kafka/broker-0

# Add these lines for new brokers
mkdir -p /host/mnt/ssd/kafka/broker-1
mkdir -p /host/mnt/ssd/kafka/broker-2

# Set permissions for all
chmod -R 755 /host/mnt/ssd/kafka
chown -R 1000:1000 /host/mnt/ssd/kafka
```

----

#### 2. Create New Persistent Volumes

You need to create new PV files for the new brokers in the `storage/pv/` directory.

**Create file: `storage/pv/kafka-pv-1.yaml`**
```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: kafka-broker-1-pv
  labels:
    type: local
    broker-id: "1"
    app: kafka
    component: broker
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

**Create file: `storage/pv/kafka-pv-2.yaml`**
```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: kafka-broker-2-pv
  labels:
    type: local
    broker-id: "2"
    app: kafka
    component: broker
spec:
  storageClassName: kafka-local-storage
  capacity:
    storage: 50Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  hostPath:
    path: /mnt/ssd/kafka/broker-2
    type: DirectoryOrCreate
```

----

#### 3. Update Deployment Script (deploy.sh)

Update `deploy.sh` to apply these new PVs before deploying the StatefulSet.

```bash
# Apply storage
kubectl apply -f storage/pv/kafka-pv-0.yaml
kubectl apply -f storage/pv/kafka-pv-1.yaml  # Add this
kubectl apply -f storage/pv/kafka-pv-2.yaml  # Add this
```

----

#### 4. Update Kafka Configuration

Update `configmaps/kafka-configmap.yaml` to increase replication factors.

```properties
# Change these values
offsets.topic.replication.factor=3
transaction.state.log.replication.factor=3
transaction.state.log.min.isr=2
default.replication.factor=3
min.insync.replicas=2
```

----

#### 5. Update StatefulSet

Update `statefulsets/kafka-statefulset.yaml` to increase the replica count.

```yaml
spec:
  replicas: 3  # Change from 1 to 3
```

----

#### 6. Apply Changes

Run your updated deployment script:

```bash
bash deploy.sh
```

The system will:
1. Create the new PVs.
2. Update the ConfigMap.
3. Scale the StatefulSet to 3 pods (k3s-kafka-0, k3s-kafka-1, k3s-kafka-2).
4. The new brokers will join the cluster automatically.

----

#### Important Notes

*   **Existing Data**: Your existing data in `broker-0` is safe. We are only adding new folders.
*   **Rebalancing**: Kafka will automatically start using the new brokers for new topics. For existing topics, you may need to run a partition reassignment tool if you want to spread them out immediately.
