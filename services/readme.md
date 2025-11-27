# Services

This directory contains Kubernetes `Service` definitions to expose applications.

## Subdirectories
- `headless/`: Services with `ClusterIP: None`, used for internal pod discovery and stable network identities.
- `nodeport/`: Services that expose the application to external traffic via a static port on each node.
