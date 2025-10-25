## Introduction to Apache Kafka

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

### Confirm that all 4 `server-broker*.properties` files are configured correctly

```bash
cat /opt/kafka/config/kraft/server-broker*.properties | grep -E 'node.id|listeners|log.dirs'
```

### Format Storage for Each Broker

Format the storage for each broker’s log directory using the `KAFKA_CLUSTER_ID`

```bash
export KAFKA_CLUSTER_ID=$(cat ~/kafka_cluster_id.txt)
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
tail -f /opt/kafka/logs/broker1.log
tail -f /opt/kafka/logs/broker2.log
```

### Create a Topic

Create a topic named `test-topic` with 4 partitions and a replication factor of 2.

```bash
/opt/kafka/bin/kafka-topics.sh --create --topic test-topic \
--replica-assignment 0:1,1:0,0:1,1:0 \
--bootstrap-server localhost:9092,localhost:9093
```
