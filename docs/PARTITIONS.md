## Kafka Partitions Explained

#### What are Partitions

Partitions are subdivisions of a Kafka topic that allow data to be distributed across multiple brokers and processed in parallel.

Think of a topic as a highway and partitions as lanes on that highway. More lanes mean more cars can travel simultaneously.

#### Why Do We Need Partitions

1. Parallel Processing
Without partitions, only one consumer can read from the topic at a time.
With 3 partitions, three consumers can read simultaneously, processing 3 times faster.

Example:
Topic: hospital (1 partition)
Consumer 1 reads all messages sequentially.

Topic: hospital (3 partitions)
Consumer 1 reads partition 0
Consumer 2 reads partition 1
Consumer 3 reads partition 2
All reading in parallel.

2. Scalability
As your hospital system grows, you can add more consumers.
Each consumer reads from different partitions.
More partitions mean more consumers and higher throughput.

Real-world scenario:
Hospital has 1000 department updates per second.
1 partition: 1 consumer processes 1000 messages per second.
3 partitions: 3 consumers each process 333 messages per second.

3. Fault Tolerance
If one consumer crashes, others keep processing their partitions.
Messages are distributed, so no single point of failure.

4. Ordering Guarantees
Kafka guarantees message order within a partition.
Messages with the same key go to the same partition.
Example: All updates for Cardiology Department go to partition 1.

Example:
Message 1: Cardiology -> Partition 1
Message 2: Cardiology Updated -> Partition 1
Message 3: Neurology -> Partition 2

#### Our Configuration

We use 3 partitions for each topic:
- hospital
- department
- designation

#### Why 3 Partitions

1. Good balance between parallelism and complexity.
2. Allows 3 concurrent consumers per topic.
3. Not too many which would add overhead.
4. Can scale up to 3x throughput compared to 1 partition.

#### How Partitions Work

Producer sends message. Kafka determines partition by key or round-robin.
Partition 0 goes to Consumer 1.
Partition 1 goes to Consumer 2.
Partition 2 goes to Consumer 3.

#### Key Takeaways

More partitions mean more parallelism and faster processing.
Partitions enable horizontal scaling.
Order is guaranteed within a partition, not across partitions.
3 partitions is a good starting point for most applications.
You cannot reduce partitions later, only increase, so choose wisely.

#### When to Increase Partitions

Increase partitions if:
- Message processing is slow.
- You want to add more consumers.
- Message volume increases significantly.

Rule of thumb:
Start with 3 to 5 partitions.
Monitor throughput.
Increase if needed.

#### For our hospital system

We expect moderate message volume.
3 partitions allow room for growth.
Can scale to 3 consumers per topic for parallel processing.
