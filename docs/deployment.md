## Deployment Guide

This guide details the deployment process for the Kafka project.

----

#### Prerequisites
- Kubernetes Cluster (K3s recommended)
- `kubectl` configured
- Root access to nodes (for storage setup)

----

#### Step 1: Prepare Host Storage
Run the setup script to create necessary directories on the host node.

```bash
bash setup.sh
```

----

#### Step 2: Deploy Components
Run the main deployment script to apply all manifests in the correct order.

```bash
bash deploy.sh
```

----

#### Verification
Check the status of the pods:

```bash
kubectl get pods -n k3s-kafka
```
