## Kafka Usage Guide

----

#### NestJS Integration

For a complete, detailed integration guide including code examples, see [NestJS Integration Guide](nestjs-usage.md).

**Installation**
```bash
npm install @nestjs/microservices kafkajs
```

**Configuration**
File: `src/kafka/kafka.module.ts`
```typescript
ClientsModule.register([
  {
    name: "KAFKA_SERVICE",
    transport: Transport.KAFKA,
    options: {
      client: {
        clientId: "k3s-api",
        brokers: [process.env.KAFKA_BOOTSTRAP_SERVERS || "localhost:30092"],
      },
      consumer: {
        groupId: "k3s-consumer-group",
      },
    },
  },
])
```

----

#### Environment Variables

**Local Development**
```env
KAFKA_BOOTSTRAP_SERVERS=192.168.1.100:30092
```

**Inside Kubernetes**
```env
KAFKA_BOOTSTRAP_SERVERS=k3s-kafka-0.k3s-kafka-headless.k3s-kafka.svc.cluster.local:9092
```

----

#### Testing

**Send Message**
```bash
kubectl exec -i -n k3s-kafka k3s-kafka-0 -- \
  kafka-console-producer \
  --topic hospital \
  --bootstrap-server localhost:9092
```

**Consume Message**
```bash
kubectl exec -n k3s-kafka k3s-kafka-0 -- \
  kafka-console-consumer \
  --topic hospital \
  --from-beginning \
  --bootstrap-server localhost:9092
```
