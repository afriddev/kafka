# Kafka Cluster for Hospital Information System

## Overview

This repository contains the complete configuration for a production-ready Kafka cluster running on Kubernetes (K3s). It is designed to support the Hospital Information System (HIS) with high availability, persistence, and scalability.

## Documentation

We have detailed documentation available in the `docs/` folder:

*   **[Deployment Guide](docs/README.md)**: Complete instructions on how to deploy, configure, and manage the cluster.
*   **[Scaling Guide](docs/SCALING.md)**: How to scale from 1 broker to 3+ brokers, including necessary code changes.
*   **[NestJS Integration](docs/NESTJS_USAGE.md)**: A comprehensive guide on connecting your NestJS microservices to this Kafka cluster.

## Quick Start

### 1. Prerequisites Check

Before running anything, verify your environment:

**Check K3s Status:**
```bash
systemctl status k3s
```

**Check kubectl CLI:**
```bash
kubectl version --short
```

### 2. Setup and Deploy

Run the automated scripts to set up storage and deploy the cluster:

```bash
# 1. Setup storage directories on the node
bash setup.sh

# 2. Deploy Kafka components
bash deploy.sh
```

### 3. Verification

Once deployed, check the health of your cluster:

**Check Pods:**
```bash
kubectl get pods -n k3s-kafka
```
*Expected Output: `k3s-kafka-0` should be `Running`.*

**Check Logs:**
```bash
kubectl logs -n k3s-kafka k3s-kafka-0
```

**Check Services:**
```bash
kubectl get svc -n k3s-kafka
```

## Project Structure

*   `kafka/`: Core Kafka StatefulSet, Service, and ConfigMap.
*   `storage/`: PersistentVolume configurations.
*   `namespace/`: Namespace definition.
*   `docs/`: Detailed documentation.
*   `setup.sh`: Script to prepare host storage.
*   `deploy.sh`: Script to apply Kubernetes manifests.

## Support

For issues regarding scaling or integration, please refer to the specific guides in the `docs/` directory.
