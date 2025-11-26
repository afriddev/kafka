# NestJS Kafka Integration Guide

## Installation

```bash
npm install @nestjs/microservices kafkajs
```

## Configuration

#### Create Kafka Module

File: src/kafka/kafka.module.ts

```typescript
import { Module } from "@nestjs/common";
import { ClientsModule, Transport } from "@nestjs/microservices";

@Module({
  imports: [
    ClientsModule.register([
      {
        name: "KAFKA_SERVICE",
        transport: Transport.KAFKA,
        options: {
          client: {
            clientId: "his-api",
            brokers: [process.env.KAFKA_BOOTSTRAP_SERVERS || "localhost:30092"],
          },
          consumer: {
            groupId: "his-consumer-group",
          },
        },
      },
    ]),
  ],
  exports: [ClientsModule],
})
export class KafkaModule {}
```

## Producer - Sending Messages

#### Create Hospital Service

File: src/hospital/hospital.service.ts

```typescript
import { Injectable, Inject, OnModuleInit } from "@nestjs/common";
import { ClientKafka } from "@nestjs/microservices";

@Injectable()
export class HospitalService implements OnModuleInit {
  constructor(
    @Inject("KAFKA_SERVICE") private readonly kafkaClient: ClientKafka
  ) {}

  async onModuleInit() {
    this.kafkaClient.subscribeToResponseOf("hospital");
    await this.kafkaClient.connect();
  }

  async createHospital(hospitalData: any) {
    return this.kafkaClient.emit("hospital", {
      key: hospitalData.id,
      value: {
        action: "CREATE",
        data: hospitalData,
        timestamp: new Date().toISOString(),
      },
    });
  }

  async updateHospital(id: string, hospitalData: any) {
    return this.kafkaClient.emit("hospital", {
      key: id,
      value: {
        action: "UPDATE",
        data: hospitalData,
        timestamp: new Date().toISOString(),
      },
    });
  }
}
```

#### Hospital Controller

File: src/hospital/hospital.controller.ts

```typescript
import { Controller, Post, Put, Body, Param } from "@nestjs/common";
import { HospitalService } from "./hospital.service";

@Controller("hospitals")
export class HospitalController {
  constructor(private readonly hospitalService: HospitalService) {}

  @Post()
  async create(@Body() createDto: any) {
    await this.hospitalService.createHospital(createDto);
    return { message: "Hospital create event published to Kafka" };
  }

  @Put(":id")
  async update(@Param("id") id: string, @Body() updateDto: any) {
    await this.hospitalService.updateHospital(id, updateDto);
    return { message: "Hospital update event published to Kafka" };
  }
}
```

#### Hospital Module

File: src/hospital/hospital.module.ts

```typescript
import { Module } from "@nestjs/common";
import { HospitalController } from "./hospital.controller";
import { HospitalService } from "./hospital.service";
import { KafkaModule } from "../kafka/kafka.module";

@Module({
  imports: [KafkaModule],
  controllers: [HospitalController],
  providers: [HospitalService],
})
export class HospitalModule {}
```

## Consumer - Receiving Messages

#### Create Consumer Service

File: src/kafka/kafka.consumer.ts

```typescript
import { Injectable, OnModuleInit } from "@nestjs/common";
import { Kafka, Consumer } from "kafkajs";

@Injectable()
export class KafkaConsumerService implements OnModuleInit {
  private kafka: Kafka;
  private consumer: Consumer;

  constructor() {
    this.kafka = new Kafka({
      clientId: "his-consumer",
      brokers: [process.env.KAFKA_BOOTSTRAP_SERVERS || "localhost:30092"],
    });

    this.consumer = this.kafka.consumer({
      groupId: "his-consumer-group",
    });
  }

  async onModuleInit() {
    await this.consumer.connect();

    await this.consumer.subscribe({
      topics: ["hospital", "designation", "department"],
      fromBeginning: false,
    });

    await this.consumer.run({
      eachMessage: async ({ topic, partition, message }) => {
        const value = JSON.parse(message.value.toString());

        console.log({
          topic,
          partition,
          offset: message.offset,
          key: message.key?.toString(),
          value,
        });

        switch (topic) {
          case "hospital":
            await this.handleHospitalEvent(value);
            break;
          case "designation":
            await this.handleDesignationEvent(value);
            break;
          case "department":
            await this.handleDepartmentEvent(value);
            break;
        }
      },
    });
  }

  private async handleHospitalEvent(data: any) {
    console.log("Hospital Event:", data);
  }

  private async handleDesignationEvent(data: any) {
    console.log("Designation Event:", data);
  }

  private async handleDepartmentEvent(data: any) {
    console.log("Department Event:", data);
  }

  async onModuleDestroy() {
    await this.consumer.disconnect();
  }
}
```

#### Update Kafka Module

File: src/kafka/kafka.module.ts

```typescript
import { Module } from "@nestjs/common";
import { ClientsModule, Transport } from "@nestjs/microservices";
import { KafkaConsumerService } from "./kafka.consumer";

@Module({
  imports: [
    ClientsModule.register([
      {
        name: "KAFKA_SERVICE",
        transport: Transport.KAFKA,
        options: {
          client: {
            clientId: "his-api",
            brokers: [process.env.KAFKA_BOOTSTRAP_SERVERS || "localhost:30092"],
          },
          consumer: {
            groupId: "his-consumer-group",
          },
        },
      },
    ]),
  ],
  providers: [KafkaConsumerService],
  exports: [ClientsModule],
})
export class KafkaModule {}
```

## Environment Configuration

Add to .env file:

```env
KAFKA_BOOTSTRAP_SERVERS=<node-ip>:30092
```

For local development (outside K8s):

```env
KAFKA_BOOTSTRAP_SERVERS=192.168.1.100:30092
```

For inside K8s cluster:

```env
KAFKA_BOOTSTRAP_SERVERS=his-kafka-cluster-kafka-bootstrap.his-kafka.svc.cluster.local:9092
```

## App Module Integration

File: src/app.module.ts

```typescript
import { Module } from "@nestjs/common";
import { ConfigModule } from "@nestjs/config";
import { KafkaModule } from "./kafka/kafka.module";
import { HospitalModule } from "./hospital/hospital.module";

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    KafkaModule,
    HospitalModule,
  ],
})
export class AppModule {}
```

## Usage Example

Send hospital create event:

```bash
curl -X POST http://localhost:3000/hospitals \
  -H "Content-Type: application/json" \
  -d '{
    "id": "hosp-001",
    "name": "City Hospital",
    "address": "123 Main St"
  }'
```

## Alternative: Microservice Pattern

#### Main File

File: src/main.ts

```typescript
import { NestFactory } from "@nestjs/core";
import { MicroserviceOptions, Transport } from "@nestjs/microservices";
import { AppModule } from "./app.module";

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  app.connectMicroservice<MicroserviceOptions>({
    transport: Transport.KAFKA,
    options: {
      client: {
        brokers: [process.env.KAFKA_BOOTSTRAP_SERVERS || "localhost:30092"],
      },
      consumer: {
        groupId: "his-consumer-group",
      },
    },
  });

  await app.startAllMicroservices();
  await app.listen(3000);
}
bootstrap();
```

#### Message Pattern Controller

File: src/events/events.controller.ts

```typescript
import { Controller } from "@nestjs/common";
import { MessagePattern, Payload } from "@nestjs/microservices";

@Controller()
export class EventsController {
  @MessagePattern("hospital")
  handleHospital(@Payload() message: any) {
    console.log("Received hospital event:", message.value);
    return { status: "processed" };
  }

  @MessagePattern("designation")
  handleDesignation(@Payload() message: any) {
    console.log("Received designation event:", message.value);
    return { status: "processed" };
  }

  @MessagePattern("department")
  handleDepartment(@Payload() message: any) {
    console.log("Received department event:", message.value);
    return { status: "processed" };
  }
}
```

## Available Topics

| Topic       | Purpose                         |
| ----------- | ------------------------------- |
| hospital    | Hospital creation/update events |
| designation | Designation management events   |
| department  | Department management events    |

## Testing

#### Check Kafka Connection

```bash
kubectl get svc -n his-kafka
kubectl get svc his-kafka-cluster-kafka-external-bootstrap -n his-kafka
```

#### Send Test Message via CLI

```bash
kubectl exec -n his-kafka his-kafka-cluster-kafka-0 -- \
  /opt/kafka/bin/kafka-console-producer.sh \
  --topic hospital \
  --bootstrap-server localhost:9092 \
  --property "key.separator=:" \
  --property "parse.key=true"
```

Then type:

```
hosp-001:{"action":"CREATE","name":"Test Hospital"}
```

#### Consume Messages via CLI

```bash
kubectl exec -n his-kafka his-kafka-cluster-kafka-0 -- \
  /opt/kafka/bin/kafka-console-consumer.sh \
  --topic hospital \
  --from-beginning \
  --bootstrap-server localhost:9092
```

## Production Best Practices

- Wrap Kafka operations in try-catch blocks
- Implement exponential backoff for retries
- Handle failed messages with dead letter queues
- Log all Kafka events for monitoring
- Use JSON Schema or Avro for validation
- Handle duplicate messages gracefully

## Complete Example

File: src/hospital/hospital.service.ts

```typescript
import { Injectable, Inject } from "@nestjs/common";
import { ClientKafka } from "@nestjs/microservices";
import { InjectRepository } from "@nestjs/typeorm";
import { Repository } from "typeorm";
import { Hospital } from "./hospital.entity";

@Injectable()
export class HospitalService {
  constructor(
    @InjectRepository(Hospital)
    private hospitalRepo: Repository<Hospital>,
    @Inject("KAFKA_SERVICE")
    private kafka: ClientKafka
  ) {}

  async create(data: any) {
    const hospital = await this.hospitalRepo.save(data);

    await this.kafka.emit("hospital", {
      key: hospital.id,
      value: {
        action: "CREATED",
        data: hospital,
        timestamp: new Date().toISOString(),
      },
    });

    return hospital;
  }

  async update(id: string, data: any) {
    await this.hospitalRepo.update(id, data);
    const hospital = await this.hospitalRepo.findOne({ where: { id } });

    await this.kafka.emit("hospital", {
      key: id,
      value: {
        action: "UPDATED",
        data: hospital,
        timestamp: new Date().toISOString(),
      },
    });

    return hospital;
  }
}
```

This ensures both database persistence and event streaming for real-time updates across microservices.
