# Kafka and FastAPI Messaging System

## Overview

This project establishes a production-grade messaging system using **Apache Kafka** in KRaft mode (without ZooKeeper) integrated with two **FastAPI** applications. Deployed on a **Debian-based Google Cloud Platform (GCP) VM**, the system ensures high throughput, fault tolerance, and scalability. The components include:

- **Kafka Cluster**: A multi-node setup hosting `test-topic` with configurable partitions and replication for high availability.
- **Producer**: A FastAPI application to send messages to `test-topic` via POST requests.
- **Consumer**: A FastAPI application to consume messages from `test-topic` and display them on an HTML page.
- **Storage**: Messages are stored persistently in Kafka logs (`/var/kafka/logs/test-topic-*`) with customizable retention policies.



## Introduction to Apache Kafka

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

## Prerequisites

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

## System Architecture

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

---

## Production-Grade Configuration

### Multi-Node Kafka Cluster

1. **Deploy Brokers**:
   - Set up 3 VMs (e.g., `broker1`, `broker2`, `broker3`).
   - Configure `server.properties` for each broker:
     ```properties
     # broker1 (/path/to/kafka/config/kraft/server.properties)
     broker.id=1
     node.id=1
     controller.quorum.voters=1@broker1:9092,2@broker2:9093,3@broker3:9094
     listeners=PLAINTEXT://broker1:9092
     advertised.listeners=PLAINTEXT://broker1:9092
     log.dirs=/var/kafka/logs
     num.partitions=6
     default.replication.factor=3
     ```
     Repeat for `broker.id=2` (port `9093`) and `broker.id=3` (port `9094`).

2. **Start Brokers**:
   - Format storage on each broker:
     ```bash
     export KAFKA_CLUSTER_ID="$(/path/to/kafka/bin/kafka-storage.sh random-uuid)"
     /path/to/kafka/bin/kafka-storage.sh format -t $KAFKA_CLUSTER_ID -c /path/to/kafka/config/kraft/server.properties
     ```
   - Start Kafka:
     ```bash
     /path/to/kafka/bin/kafka-server-start.sh /path/to/kafka/config/kraft/server.properties &
     ```

### Topic Configuration

- Create `test-topic` with 6 partitions and replication factor 3:
  ```bash
  /path/to/kafka/bin/kafka-topics.sh --create --topic test-topic --bootstrap-server broker1:9092 --partitions 6 --replication-factor 3
  ```

### Retention Policies

- Configure in `server.properties`:
  ```properties
  log.retention.hours=168  # 7 days
  log.retention.bytes=1073741824  # 1GB per partition
  log.retention.check.interval.ms=300000  # Check every 5 minutes
  ```

### Performance Tuning

- **Memory**:
  ```bash
  export KAFKA_HEAP_OPTS="-Xmx4g -Xms4g"
  ```
- **Threads**:
  ```properties
  num.io.threads=8
  num.network.threads=3
  ```
- **Compression**:
  ```properties
  compression.type=gzip
  ```
- **Log Segment Size**:
  ```properties
  log.segment.bytes=1073741824  # 1GB per segment
  ```

### Systemd Integration

- Create a systemd service for each Kafka broker:
  ```bash
  sudo nano /etc/systemd/system/kafka.service
  ```
  ```ini
  [Unit]
  Description=Apache Kafka Server
  After=network.target

  [Service]
  Type=simple
  Environment="KAFKA_HEAP_OPTS=-Xmx4g -Xms4g"
  ExecStart=/path/to/kafka/bin/kafka-server-start.sh /path/to/kafka/config/kraft/server.properties
  ExecStop=/path/to/kafka/bin/kafka-server-stop.sh
  Restart=on-failure

  [Install]
  WantedBy=multi-user.target
  ```
  ```bash
  sudo systemctl enable kafka
  sudo systemctl start kafka
  ```

- Create systemd services for FastAPI apps:
  ```bash
  sudo nano /etc/systemd/system/producer.service
  ```
  ```ini
  [Unit]
  Description=FastAPI Producer
  After=network.target

  [Service]
  User=your_user
  WorkingDirectory=/path/to/producer
  ExecStart=/path/to/venv/bin/uvicorn main_producer:app --host 0.0.0.0 --port 8001 --workers 4
  Restart=always

  [Install]
  WantedBy=multi-user.target
  ```
  Repeat for `consumer.service` (port `8002`).

### FastAPI Scaling

- Run with multiple workers:
  ```bash
  /path/to/venv/bin/uvicorn main_producer:app --host 0.0.0.0 --port 8001 --workers 4
  ```
- Deploy behind NGINX for load balancing:
  ```nginx
  upstream producer {
      server 127.0.0.1:8001;
      server 127.0.0.1:8003;  # Additional instance
  }

  server {
      listen 80;
      server_name producer.example.com;
      location / {
          proxy_pass http://producer;
          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
      }
  }
  ```

### Load Balancing

- Use NGINX to balance Kafka traffic across brokers:
  ```nginx
  upstream kafka {
      server broker1:9092;
      server broker2:9093;
      server broker3:9094;
  }
  ```

---

## Setup Instructions

### Install Java

```bash
sudo apt update
sudo apt install -y default-jre
java -version
```

### Install Kafka

1. Download Kafka 3.9.1:
   ```bash
   wget https://downloads.apache.org/kafka/3.9.1/kafka_2.13-3.9.1.tgz
   tar -xzf kafka_2.13-3.9.1.tgz
   mv kafka_2.13-3.9.1 /path/to/kafka
   ```

2. Create log directory:
   ```bash
   sudo mkdir -p /var/kafka/logs
   sudo chown $USER:$USER /var/kafka/logs
   ```

### Set Up Python Environment

1. Create and activate virtual environment:
   ```bash
   python3 -m venv ~/kafka/venv
   source ~/kafka/venv/bin/activate
   ```

2. Install dependencies:
   ```bash
   pip install fastapi uvicorn aiokafka python-dotenv markdown2 weasyprint
   ```

### Configure Kafka

1. Generate cluster ID:
   ```bash
   export KAFKA_CLUSTER_ID="$(/path/to/kafka/bin/kafka-storage.sh random-uuid)"
   ```

2. Format storage:
   ```bash
   /path/to/kafka/bin/kafka-storage.sh format -t $KAFKA_CLUSTER_ID -c /path/to/kafka/config/kraft/server.properties
   ```

3. Start Kafka (repeat for each broker):
   ```bash
   /path/to/kafka/bin/kafka-server-start.sh /path/to/kafka/config/kraft/server.properties &
   ```

4. Create topic:
   ```bash
   /path/to/kafka/bin/kafka-topics.sh --create --topic test-topic --bootstrap-server broker1:9092 --partitions 6 --replication-factor 3
   ```

### Deploy FastAPI Apps

- See [Producer FastAPI Application](#producer-fastapi-application) and [Consumer FastAPI Application](#consumer-fastapi-application) for code and deployment details.

### Configure GCP Firewall

```bash
gcloud compute firewall-rules create allow-kafka --allow tcp:9092-9094
gcloud compute firewall-rules create allow-producer --allow tcp:8001
gcloud compute firewall-rules create allow-consumer --allow tcp:8002
```

---

## Producer FastAPI Application

### Producer Code

**File**: `main_producer.py`

```python
from fastapi import FastAPI
from aiokafka import AIOKafkaProducer
import json
from fastapi.responses import JSONResponse
from dotenv import load_dotenv
import os

load_dotenv()

app = FastAPI()
producer = None

@app.on_event("startup")
async def startup():
    global producer
    bootstrap_servers = os.getenv("KAFKA_BOOTSTRAP_SERVERS", "broker1:9092,broker2:9093,broker3:9094")
    producer = AIOKafkaProducer(bootstrap_servers=bootstrap_servers)
    await producer.start()

@app.on_event("shutdown")
async def shutdown():
    await producer.stop()

@app.post("/send")
async def send_message(msg: dict):
    await producer.send('test-topic', json.dumps(msg).encode('utf-8'))
    return JSONResponse({"status": "sent"})

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8001)
```

### Producer Deployment

```bash
source ~/kafka/venv/bin/activate
python main_producer.py
```

### Producer Configuration

- Create `.env` file:
  ```env
  KAFKA_BOOTSTRAP_SERVERS=broker1:9092,broker2:9093,broker3:9094
  ```

---

## Consumer FastAPI Application

### Consumer Code

**File**: `main_consumer.py`

```python
from fastapi import FastAPI
from aiokafka import AIOKafkaConsumer
import asyncio
import json
from fastapi.responses import HTMLResponse
from dotenv import load_dotenv
import os

load_dotenv()

app = FastAPI()
messages = []

@app.on_event("startup")
async def startup():
    bootstrap_servers = os.getenv("KAFKA_BOOTSTRAP_SERVERS", "broker1:9092,broker2:9093,broker3:9094")
    consumer = AIOKafkaConsumer('test-topic', bootstrap_servers=bootstrap_servers, group_id='test-group')
    await consumer.start()
    asyncio.create_task(consume(consumer))

async def consume(consumer):
    async for msg in consumer:
        messages.append(json.loads(msg.value.decode('utf-8')))

@app.get("/", response_class=HTMLResponse)
async def read_root():
    html = "<html><body><h1>Kafka Messages</h1><ul>" + "".join([f"<li>{m}</li>" for m in messages[-10:]]) + "</ul></body></html>"
    return HTMLResponse(content=html)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8002)
```

### Consumer Deployment

```bash
source ~/kafka/venv/bin/activate
python main_consumer.py
```

### Consumer Configuration

- Use the same `.env` file as the producer.

---

## Testing the System

### Verify Kafka

```bash
/path/to/kafka/bin/kafka-topics.sh --list --bootstrap-server broker1:9092
```

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

## Message Storage and Retention

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

## Monitoring and Maintenance

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

## Scaling Kafka

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

## Security Considerations

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

### FastAPI Security

- Use HTTPS with NGINX:
  ```nginx
  server {
      listen 443 ssl;
      server_name producer.example.com;
      ssl_certificate /path/to/cert.pem;
      ssl_certificate_key /path/to/key.pem;
      location / {
          proxy_pass http://127.0.0.1:8001;
      }
  }
  ```
- Add API key authentication to `/send`:
  ```python
  from fastapi.security import APIKeyHeader
  api_key_header = APIKeyHeader(name="X-API-Key")
  @app.post("/send")
  async def send_message(msg: dict, api_key: str = Depends(api_key_header)):
      if api_key != "your-secret-key":
          raise HTTPException(status_code=401, detail="Invalid API Key")
      await producer.send('test-topic', json.dumps(msg).encode('utf-8'))
      return JSONResponse({"status": "sent"})
  ```

---

## Troubleshooting

### Common Kafka Issues

- **Broker Not Starting**:
  - Check `/path/to/kafka/logs/server.log`.
  - Ensure `KAFKA_CLUSTER_ID` is set and storage is formatted.
  - Verify port `9092` is not in use: `netstat -tuln | grep 9092`.
- **Topic Creation Fails**:
  - Ensure all brokers are running.
  - Check `bootstrap-server` address.

### Common FastAPI Issues

- **Connection Errors**:
  - Verify Kafka brokers are accessible: `telnet broker1 9092`.
  - Check `.env` for correct `KAFKA_BOOTSTRAP_SERVERS`.
- **No Messages Displayed**:
  - Ensure consumer is in `test-group`.
  - Check consumer logs for errors.

### Debugging Tips

- View Kafka logs: `/path/to/kafka/logs/server.log`.
- Use console consumer for debugging:
  ```bash
  /path/to/kafka/bin/kafka-console-consumer.sh --topic test-topic --bootstrap-server broker1:9092 --from-beginning
  ```
- Check consumer group status:
  ```bash
  /path/to/kafka/bin/kafka-consumer-groups.sh --bootstrap-server broker1:9092 --group test-group --describe
  ```

---

## Best Practices

### Kafka Best Practices

- Use at least 3 brokers for fault tolerance.
- Set replication factor to 3 for critical topics.
- Monitor consumer lag and broker health.
- Use compression (e.g., `gzip`) for high-throughput topics.
- Regularly back up topic data.

### FastAPI Best Practices

- Use environment variables for configuration.
- Implement rate limiting and authentication.
- Deploy behind a reverse proxy (e.g., NGINX).
- Use multiple workers for high traffic.

---

## Access Points

- **Kafka Brokers**: `broker1:9092`, `broker2:9093`, `broker3:9094`.
- **Producer API**: `http://localhost:8001/send` (POST).
- **Consumer UI**: `http://localhost:8002` (GET).

---

## References

- [Apache Kafka Documentation](https://kafka.apache.org/documentation/)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [AIOKafka Documentation](https://aiokafka.readthedocs.io/)
- [GCP Networking](https://cloud.google.com/vpc/docs)
- [WeasyPrint Documentation](https://weasyprint.readthedocs.io/)

---

## Advanced Topics

### Kafka Streams

Kafka Streams is a client library for building stream-processing applications. It allows processing data in real-time directly from Kafka topics.

### Kafka Connect

Kafka Connect is a framework for integrating Kafka with external systems (e.g., databases, cloud storage). Use it to stream data to/from `test-topic`.

### Schema Registry

Confluent Schema Registry ensures data compatibility by managing message schemas. Recommended for production to enforce data contracts.

---

## Appendix

### Kafka Configuration Options

- `broker.id`: Unique ID for each broker.
- `log.retention.hours`: Time-based retention for logs.
- `num.partitions`: Default number of partitions for new topics.
- `default.replication.factor`: Default replication factor.

### FastAPI Configuration Options

- `--workers`: Number of Uvicorn workers.
- `--host`: Bind address (e.g., `0.0.0.0`).
- `--port`: Port for the application.

### Glossary

- **KRaft**: Kafka Raft protocol for metadata management.
- **Partition**: A division of a topic’s messages.
- **Replication**: Copying partitions across brokers.
- **Consumer Group**: A group of consumers sharing a topic’s load.
