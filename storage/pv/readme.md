# PersistentVolumes (PV)

This directory contains `PersistentVolume` definitions. Since we are using local storage, these PVs map directly to directories on the host node.

## Files
- `kafka-pv-0.yaml`: PV for Broker 0, mapped to `/mnt/ssd/kafka/broker-0`.
