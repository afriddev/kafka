## Scaling Kafka

#### Understanding Brokers and Clusters

When we talk about scaling, we mean adding more power to our system. A cluster is a group of computers working together. In Kafka, these computers are called brokers.

If we have 3 brokers in our cluster, they work as a team. When you send data to Kafka, it does not just go to one place. It gets copied to multiple brokers. This is called replication.

#### How Topics are Distributed

When you create a topic, you want it to be safe. If you have 3 brokers, you should set your topic to be on all 3 brokers.

This means if one broker fails or crashes, the other two still have your data. The system keeps working without stopping. This is what we mean by high availability.

#### Leader and Followers

In this team of 3 brokers, for each piece of data, one broker is the Leader. The others are Followers.

The Leader handles all the work. The Followers just copy everything the Leader does to stay in sync.

If the Leader crashes, one of the Followers immediately becomes the new Leader. This happens automatically so your application does not stop working.

#### Adding More Brokers

If you need more speed or space, you can add more brokers.

When you add a new broker, Kafka can move some work to it. This helps balance the load so no single broker is doing too much.

#### Summary of Requirements

To make this work, you need:
1. Multiple brokers (computers) in your cluster.
2. Topics configured to use these brokers (replication factor).
3. Storage space for each broker.
