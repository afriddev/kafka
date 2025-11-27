# Kafka Project

## Overview
Production-ready Apache Kafka deployment on Kubernetes using standard manifests.

----

## Quick Start

1. **Setup Storage**
   ```bash
   bash setup.sh
   ```

2. **Deploy**
   ```bash
   bash deploy.sh
   ```

----

## Documentation

- [Deployment Guide](docs/deployment.md)
- [Storage Architecture](docs/storage.md)
- [Scaling Guide](docs/scaling.md)
- [Usage Guide](docs/usage.md)
- [NestJS Integration Guide](docs/nestjs-usage.md)
- [Production Resources](docs/production-resources.md)

----

## Architecture

- **Namespace**: `k3s-kafka`
- **Storage**: HostPath at `/mnt/ssd/kafka`
- **Service**: Headless (Internal) & NodePort (External)
