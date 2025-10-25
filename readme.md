# Kafka and FastAPI Messaging System

### Overview

This project establishes a production-grade messaging system using **Apache Kafka** in KRaft mode (without ZooKeeper) integrated with two **FastAPI** applications. Deployed on a **Debian-based Google Cloud Platform (GCP) VM**, the system ensures high throughput, fault tolerance, and scalability. The components include:

- **Kafka Cluster**: A multi-node setup hosting `test-topic` with configurable partitions and replication for high availability.
- **Producer**: A FastAPI application to send messages to `test-topic` via POST requests.
- **Consumer**: A FastAPI application to consume messages from `test-topic` and display them on an HTML page.
- **Storage**: Messages are stored persistently in Kafka logs (`/var/kafka/logs/test-topic-*`) with customizable retention policies.

### Introduction to Apache Kafka

### What is Kafka?

**Apache Kafka** is a distributed streaming platform designed for high-throughput, fault-tolerant, and scalable event streaming. It is widely used for building real-time data pipelines, event-driven architectures, and microservices communication. Kafka operates as a publish-subscribe messaging system, where producers publish messages to topics, and consumers subscribe to process them.

Kafka is used by thousands of organizations for applications like log aggregation, stream processing, and event sourcing. Its ability to handle large-scale data with low latency makes it a cornerstone of modern data architectures.

### Key Concepts

- **Broker**: A Kafka server that stores and manages messages. Multiple brokers form a cluster for redundancy and scalability.
- **Topic**: A logical channel for messages, divided into partitions for parallel processing.
- **Partition**: A subset of a topic’s messages, stored on a single broker. Partitions enable parallelism and load balancing.
- **Replication**: Copies of partitions across brokers to ensure fault tolerance and data durability.
- **Producer**: An application that sends messages to a topic.
- **Consumer**: An application that reads messages from a topic.
- **Consumer Group**: A group of consumers that share the load of processing a topic’s messages.
- **Offset**: A unique identifier for each message in a partition, used for tracking consumer progress.
- **KRaft**: Kafka’s Raft-based consensus protocol for metadata management, replacing ZooKeeper.
- **Leader and Follower**: Each partition has a leader (handles reads/writes) and followers (replicas for fault tolerance).
- **Log**: An append-only sequence of messages stored on disk for each partition.

### Why Kafka?

Kafka is chosen for its:

- **High Throughput**: Processes millions of messages per second.
- **Fault Tolerance**: Replicated partitions prevent data loss.
- **Scalability**: Scales horizontally by adding brokers or partitions.
- **Durability**: Persists messages to disk with configurable retention.
- **Real-Time Processing**: Enables low-latency data streaming.
- **Ecosystem**: Integrates with tools like Kafka Streams, Kafka Connect, and Schema Registry.

### KRaft Mode

Introduced in Kafka 2.8, **KRaft (Kafka Raft)** replaces ZooKeeper with a Raft-based consensus protocol for metadata management. Benefits include:

- Simplified architecture (no external dependency).
- Faster leader election and recovery.
- Improved scalability for large clusters.
- Easier deployment and maintenance.

KRaft mode is ideal for production environments, reducing operational complexity and improving cluster resilience.

### Kafka Architecture

Kafka’s architecture consists of:

- **Brokers**: Servers that store data and serve clients. Each broker holds partitions of topics.
- **Topics and Partitions**: Messages are organized into topics, split into partitions for parallel processing.
- **Replication**: Each partition has replicas (leader and followers) for fault tolerance.
- **Producers and Consumers**: Producers write to partitions, and consumers read from them, often in groups.
- **Metadata**: Managed by KRaft controllers, which handle broker coordination and partition assignments.
- **Log Structure**: Messages are stored in append-only logs, ensuring durability and sequential access.

Kafka’s design allows it to handle high volumes of data with low latency, making it suitable for real-time applications like event streaming, log aggregation, and microservices communication.

---

### Prerequisites

### Hardware Requirements

- **GCP VM (per broker)**:
  - **Development**: 2 vCPUs, 4GB RAM, 20GB SSD.
  - **Production**: 4+ vCPUs, 16GB RAM, 100GB+ NVMe SSD.
  - Minimum 3 VMs for a production cluster to ensure fault tolerance.
- **Disk**: Dedicated disk for Kafka logs (e.g., 100GB+ per broker).
- **Network**: Low-latency, high-bandwidth network (e.g., GCP VPC).

### Software Requirements

- **OS**: Debian 11 or Ubuntu 20.04.
- **Java**: `default-jre` (Java 11+).
- **Python**: Python 3.11+ with `venv`.
- **Kafka**: Version 3.9.1 (download from `https://kafka.apache.org/downloads`).
- **Python Libraries**: `fastapi`, `uvicorn`, `aiokafka`, `python-dotenv`.
- **PDF Generation (optional)**: `markdown2`, `weasyprint` for converting Markdown to PDF.

### Networking

- **Ports**:
  - `9092-9094`: Kafka brokers (one per broker).
  - `8001`: Producer FastAPI app.
  - `8002`: Consumer FastAPI app.
- **GCP Firewall**: Allow TCP traffic on these ports.
- **VPC**: Use private subnets with NAT for production.
- **Static IP**: Assign static external IPs to VMs for external access.

### Permissions

- User with `sudo` access for installing packages and managing services.
- Write access to `/var/kafka/logs` for Kafka logs.
- GCP IAM roles: `Compute Admin` and `Network Admin` for VM and firewall management.

---

### System Architecture

### Component Overview

1. **Kafka Cluster**:

   - Multi-node setup (3 brokers recommended for production).
   - Hosts `test-topic` with 6 partitions and replication factor 3.
   - Uses KRaft mode for metadata management.

2. **Producer FastAPI App**:

   - Exposes `/send` endpoint to publish JSON messages to `test-topic`.
   - Uses `aiokafka` for asynchronous Kafka integration.
   - Runs on port `8001`.

3. **Consumer FastAPI App**:

   - Consumes messages from `test-topic` using the `test-group` consumer group.
   - Displays the last 10 messages on an HTML page via `/` endpoint.
   - Runs on port `8002`.

4. **Storage**:

   - Messages stored in `/var/kafka/logs/test-topic-*`.
   - Configurable retention (e.g., 7 days or 1GB per partition).

### Data Flow

1. Producer sends JSON messages to `test-topic` via POST `/send`.
2. Kafka distributes messages across partitions, replicating them across brokers.
3. Consumer reads messages from `test-topic`, maintaining offsets in the `test-group`.
4. Consumer displays messages on an HTML page.

### Apache Kafka 2-Broker Cluster Setup Guide

### Overview

This guide explains how to set up a **2-broker Apache Kafka cluster** using KRaft mode, suitable for small production or development environments.  
 It includes installation, configuration, startup, topic creation, and verification steps.

---

### Prerequisites

- Ubuntu/Debian system
- Java 11+ installed
- Minimum 16GB RAM and SSD recommended

## Launching Apache Kafka with KRaft Mode on Ubuntu 22.04 And 2 Brokers

### Install Java

```bash
sudo apt install -y default-jre
java -version
# If the output shows a version lower than 11
sudo apt install -y openjdk-11-jre
java -version
```

### Download Kafka

```bash
wget https://downloads.apache.org/kafka/3.9.1/kafka_2.13-3.9.1.tgz
tar -xzf kafka_2.13-3.9.1.tgz
sudo mv kafka_2.13-3.9.1 /opt/kafka
```

### Set kafka logs directory and add permissions

```bash
  sudo mkdir -p /var/kafka/logs
  sudo chown $USER:$USER /var/kafka/logs
  sudo chmod 755 /var/kafka/logs
```

### Create Log Directories for Each Broker

Each broker needs its own log directory to store messages and metadata. We’ll create separate directories (/var/kafka/logs/broker1, /var/kafka/logs/broker2, etc.) to avoid conflicts.

```bash
 sudo mkdir -p /var/kafka/logs/{broker1,broker2}
 sudo chown $USER:$USER /var/kafka/logs/broker{1,2}
 sudo chmod 755 /var/kafka/logs/broker{1,2}
```

### Generate and Save the Cluster ID

```bash
export KAFKA_CLUSTER_ID=$(/opt/kafka/bin/kafka-storage.sh random-uuid)
echo $KAFKA_CLUSTER_ID > ~/kafka_cluster_id.txt
cat ~/kafka_cluster_id.txt
```

### Configure `server.properties` for Each Broker

Create and configure a server.properties file for each broker with unique settings (ports, IDs, log directories) and a shared KRaft.

```bash
sudo cp /opt/kafka/config/kraft/server.properties /opt/kafka/config/kraft/server-broker1.properties
sudo cp /opt/kafka/config/kraft/server.properties /opt/kafka/config/kraft/server-broker2.properties
```

### Clean Up Extra Configuration Files

Remove unnecessary configuration files from /opt/kafka/config/kraft/ to avoid confusion, keeping only server-broker{1,2}.properties. Verify that all broker configurations are correct.

```bash
sudo rm /opt/kafka/config/kraft/broker.properties
sudo rm /opt/kafka/config/kraft/controller.properties
sudo rm /opt/kafka/config/kraft/reconfig-server.properties
sudo rm /opt/kafka/config/kraft/server.properties
```

### Edit each file with production settings:

```bash
sudo nano /opt/kafka/config/kraft/server-broker1.properties
```

Replace the entire content with

```bash
process.roles=broker,controller
node.id=1
controller.quorum.voters=1@localhost:10092,2@localhost:10093
listeners=PLAINTEXT://localhost:9092,CONTROLLER://localhost:10092
advertised.listeners=PLAINTEXT://localhost:9092
inter.broker.listener.name=PLAINTEXT
controller.listener.names=CONTROLLER
listener.security.protocol.map=CONTROLLER:PLAINTEXT,PLAINTEXT:PLAINTEXT
log.dirs=/var/kafka/logs/broker1
num.partitions=4
default.replication.factor=2
offsets.topic.replication.factor=2
transaction.state.log.replication.factor=2
transaction.state.log.min.isr=2
num.network.threads=2
num.io.threads=4
socket.send.buffer.bytes=102400
socket.receive.buffer.bytes=102400
socket.request.max.bytes=104857600
log.retention.hours=168
log.retention.bytes=1073741824
log.segment.bytes=1073741824
log.retention.check.interval.ms=300000
compression.type=gzip
```

Do the same for all remaining brokers. Just make sure to change the following settings for each broker:

- `node.id` (2 for broker2)
- `listeners` and `advertised.listeners` ports (9093 for broker2)
- `log.dirs` to point to the respective broker log directory (broker2)
- `controller ports` (10093 for broker2)

### Confirm that all 2 `server-broker*.properties` files are configured correctly

```bash
cat /opt/kafka/config/kraft/server-broker*.properties | grep -E 'node.id|listeners|log.dirs'
```

### Format Storage for Each Broker

Format the storage for each broker’s log directory using the `KAFKA_CLUSTER_ID`

```bash
export KAFKA_CLUSTER_ID=$(cat ~/kafka_cluster_id.txt)
sudo rm -rf /var/kafka/logs/broker1 /var/kafka/logs/broker2
/opt/kafka/bin/kafka-storage.sh format -t $KAFKA_CLUSTER_ID -c /opt/kafka/config/kraft/server-broker1.properties
/opt/kafka/bin/kafka-storage.sh format -t $KAFKA_CLUSTER_ID -c /opt/kafka/config/kraft/server-broker2.properties

```

### Start All 2 Brokers

Start each broker with 4GB of memory (ensure VM has 16GB+ RAM).

```bash
export KAFKA_HEAP_OPTS="-Xmx4g -Xms4g"
/opt/kafka/bin/kafka-server-start.sh /opt/kafka/config/kraft/server-broker1.properties &
/opt/kafka/bin/kafka-server-start.sh /opt/kafka/config/kraft/server-broker2.properties &
```

### Verify Brokers are Running

Check the logs to ensure each broker has started successfully.

```bash
ps aux | grep kafka
```

### Create Topic (4 Partitions, 2 Replicas)

Create a topic named `test-topic` with 4 partitions and a replication factor of 2.

```bash
/opt/kafka/bin/kafka-topics.sh --create --topic test-topic \
--replica-assignment 1:2,2:1,1:2,2:1 \
--bootstrap-server localhost:9092,localhost:9093
```

Verify the topic was created successfully.

```bash
/opt/kafka/bin/kafka-topics.sh --describe --topic test-topic --bootstrap-server localhost:9092
/opt/kafka/bin/kafka-topics.sh --describe --topic test-topic --bootstrap-server localhost:9093
```

### Producer FastAPI Application

### Create and activate venv

```bash
python3 -m venv venv
source venv/bin/activate  # (Windows: venv\Scripts\activate)
```

### Install dependencies

```bash
pip install fastapi uvicorn aiokafka python-dotenv python-multipart
```

**File**: [producer.py](producer.py)

````

### Producer Deployment

```bash
source ~/kafka/venv/bin/activate
python main_producer.py
````

### Producer Configuration

- Create `.env` file:
  ```env
  KAFKA_BOOTSTRAP_SERVERS=localhost:9092,localhost:9093
  ```

---

### Consumer FastAPI Application

### Consumer Code

**File**: [consumer.py](consumer.py)

### Consumer Deployment

```bash
source ~/kafka/venv/bin/activate
python main_consumer.py
```

### Consumer Configuration

- Use the same `.env` file as the producer.

### Send Messages

- Use `curl` or Postman:

  ```bash
  curl -X POST http://localhost:8001/send -H "Content-Type: application/json" -d '{"key": "Hello Kafka!"}'
  ```

### View Messages

- Open `http://localhost:8002` in a browser to see the last 10 messages.

### Debugging with Console Consumer

```bash
/path/to/kafka/bin/kafka-console-consumer.sh --topic test-topic --bootstrap-server broker1:9092 --from-beginning
```

---

### Message Storage and Retention

### Storage Location

- Messages are stored in `/var/kafka/logs/test-topic-*` (one directory per partition).
- Ensure sufficient disk space (e.g., 100GB+ per broker).

### Retention Configuration

- Configured in `server.properties`:
  ```properties
  log.retention.hours=168
  log.retention.bytes=1073741824
  ```

### Manual Deletion

- Delete topic:
  ```bash
  /path/to/kafka/bin/kafka-topics.sh --delete --topic test-topic --bootstrap-server broker1:9092
  ```
- Clear logs manually (if needed):
  ```bash
  sudo rm -rf /var/kafka/logs/test-topic-*
  ```

---

### Monitoring and Maintenance

### Monitoring Tools

- **Kafka Manager**: Web-based tool for cluster management.
- **Confluent Control Center**: Comprehensive monitoring solution.
- **Prometheus + Grafana**: For metrics like lag, throughput, and broker health.
- Enable JMX:
  ```properties
  JMX_PORT=9999
  ```
  ```bash
  export JMX_PORT=9999
  /path/to/kafka/bin/kafka-server-start.sh /path/to/kafka/config/kraft/server.properties &
  ```

### Log Rotation

- Configure log rotation for Kafka logs:
  ```bash
  sudo nano /etc/logrotate.d/kafka
  ```
  ```logrotate
  /var/kafka/logs/*.log {
      daily
      rotate 7
      compress
      missingok
      notifempty
      create 640 kafka kafka
  }
  ```

### Backup Strategies

- Back up `/var/kafka/logs` to GCP Cloud Storage:
  ```bash
  gsutil cp -r /var/kafka/logs gs://your-bucket/kafka-backup/
  ```
- Use `kafkacat` for topic backup:
  ```bash
  kafkacat -b broker1:9092 -t test-topic -C -o beginning -e > backup.json
  ```

### Health Checks

- Monitor broker health:
  ```bash
  /path/to/kafka/bin/kafka-broker-info.sh --bootstrap-server broker1:9092
  ```
- Check consumer lag:
  ```bash
  /path/to/kafka/bin/kafka-consumer-groups.sh --bootstrap-server broker1:9092 --group test-group --describe
  ```

---

### Scaling Kafka

### Adding Brokers

- Deploy additional VMs and configure `server.properties`.
- Update `controller.quorum.voters` in all brokers.
- Rebalance partitions:
  ```bash
  /path/to/kafka/bin/kafka-reassign-partitions.sh --bootstrap-server broker1:9092
  ```

### Increasing Partitions

- Add partitions to `test-topic`:
  ```bash
  /path/to/kafka/bin/kafka-topics.sh --alter --topic test-topic --partitions 12 --bootstrap-server broker1:9092
  ```

### Consumer Scaling

- Add more consumer instances to `test-group`:
  ```bash
  python main_consumer.py  # Run additional instances
  ```
- Ensure stateless consumers to avoid rebalancing issues.

---

### Security Considerations

### Network Security

- Use GCP VPC with private subnets.
- Restrict firewall rules to specific IP ranges:
  ```bash
  gcloud compute firewall-rules create allow-kafka --allow tcp:9092-9094 --source-ranges your-ip-range
  ```

### Kafka Security

- Enable SSL/TLS:
  ```properties
  listeners=SSL://:9093
  security.inter.broker.protocol=SSL
  ssl.keystore.location=/path/to/keystore.jks
  ssl.keystore.password=your_password
  ```
- Configure SASL/PLAIN:
  ```properties
  sasl.enabled.mechanisms=PLAIN
  sasl.mechanism.inter.broker.protocol=PLAIN
  ```
