# Headless Services

Headless services (`ClusterIP: None`) allow direct access to individual pods and are required for StatefulSet discovery.

## Files
- `kafka-headless.yaml`: Used by the Kafka brokers for inter-broker communication and controller quorum discovery.
