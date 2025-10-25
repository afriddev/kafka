## Apache Kafka 2-Broker Cluster Setup Guide

### Overview
This guide explains how to set up a **2-broker Apache Kafka cluster** using KRaft mode, suitable for small production or development environments.  
It includes installation, configuration, startup, topic creation, and verification steps.

---

### Prerequisites
- Ubuntu/Debian system
- Java 11+ installed
- Minimum 16GB RAM and SSD recommended

---

### 1. Install Java

```bash
sudo apt install -y default-jre
java -version
# If version < 11
sudo apt install -y openjdk-11-jre
java -version
```

---

### 2. Download and Extract Kafka

```bash
wget https://downloads.apache.org/kafka/3.9.1/kafka_2.13-3.9.1.tgz
tar -xzf kafka_2.13-3.9.1.tgz
sudo mv kafka_2.13-3.9.1 /opt/kafka
```

---

### 3. Setup Log Directories

```bash
sudo mkdir -p /var/kafka/logs/{broker1,broker2}
sudo chown $USER:$USER /var/kafka/logs/broker{1,2}
sudo chmod 755 /var/kafka/logs/broker{1,2}
```

---

### 4. Generate Cluster ID

```bash
export KAFKA_CLUSTER_ID=$(/opt/kafka/bin/kafka-storage.sh random-uuid)
echo $KAFKA_CLUSTER_ID > ~/kafka_cluster_id.txt
cat ~/kafka_cluster_id.txt
```

---

### 5. Configure Each Broker

Copy base config:
```bash
sudo cp /opt/kafka/config/kraft/server.properties /opt/kafka/config/kraft/server-broker1.properties
sudo cp /opt/kafka/config/kraft/server.properties /opt/kafka/config/kraft/server-broker2.properties
```

Clean extras:
```bash
sudo rm /opt/kafka/config/kraft/{broker.properties,controller.properties,reconfig-server.properties,server.properties}
```

Edit `/opt/kafka/config/kraft/server-broker1.properties`:
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

Edit `/opt/kafka/config/kraft/server-broker2.properties` and change:
- `node.id=2`
- `listeners=PLAINTEXT://localhost:9093,CONTROLLER://localhost:10093`
- `advertised.listeners=PLAINTEXT://localhost:9093`
- `log.dirs=/var/kafka/logs/broker2`

---

### 6. Format Storage

```bash
export KAFKA_CLUSTER_ID=$(cat ~/kafka_cluster_id.txt)
/opt/kafka/bin/kafka-storage.sh format -t $KAFKA_CLUSTER_ID -c /opt/kafka/config/kraft/server-broker1.properties
/opt/kafka/bin/kafka-storage.sh format -t $KAFKA_CLUSTER_ID -c /opt/kafka/config/kraft/server-broker2.properties
```

---

### 7. Start Brokers

```bash
export KAFKA_HEAP_OPTS="-Xmx4g -Xms4g"
/opt/kafka/bin/kafka-server-start.sh /opt/kafka/config/kraft/server-broker1.properties &
/opt/kafka/bin/kafka-server-start.sh /opt/kafka/config/kraft/server-broker2.properties &
```

Check logs:
```bash
tail -f /opt/kafka/logs/broker1.log
tail -f /opt/kafka/logs/broker2.log
```

---

### 8. Create Topic (4 Partitions, 2 Replicas)

```bash
/opt/kafka/bin/kafka-topics.sh --create --topic test-topic --replica-assignment 0:1,1:0,0:1,1:0 --bootstrap-server localhost:9092,localhost:9093
```

---

### 9. Verify Setup

List topics:
```bash
/opt/kafka/bin/kafka-topics.sh --list --bootstrap-server localhost:9092,localhost:9093
```

Describe topic:
```bash
/opt/kafka/bin/kafka-topics.sh --describe --topic test-topic --bootstrap-server localhost:9092,localhost:9093
```

List brokers (via logs or metadata):
```bash
grep "Registered broker" /opt/kafka/logs/broker*.log
```

---

### 10. Useful Commands

Stop all brokers:
```bash
pkill -f kafka.Kafka
```

Delete topic:
```bash
/opt/kafka/bin/kafka-topics.sh --delete --topic test-topic --bootstrap-server localhost:9092,localhost:9093
```

Producer test:
```bash
/opt/kafka/bin/kafka-console-producer.sh --topic test-topic --bootstrap-server localhost:9092
```

Consumer test:
```bash
/opt/kafka/bin/kafka-console-consumer.sh --topic test-topic --from-beginning --bootstrap-server localhost:9092
```

---

### Notes
- Logs: `/var/kafka/logs/broker*`
- Configs: `/opt/kafka/config/kraft/server-broker*.properties`
- Use replication factor 2 for fault tolerance.
- Scale by adding brokers and increasing partitions as needed.
