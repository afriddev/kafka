# StatefulSets

This directory contains `StatefulSet` YAML files. StatefulSets are used for applications that require stable network identifiers, stable persistent storage, and ordered deployment/scaling.

## Files
- `kafka-statefulset.yaml`: Defines the Kafka Broker deployment, ensuring each broker has a stable identity (e.g., `k3s-kafka-0`) and dedicated persistent storage.
