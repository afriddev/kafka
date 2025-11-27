## Storage Architecture

----

#### Overview
- **Type**: HostPath (Local Storage)
- **Path**: `/mnt/ssd/kafka/`
- **Provisioner**: Manual (Static Provisioning)

----

#### Directory Structure on Host
- `/mnt/ssd/kafka/broker-0` -> Mapped to Broker 0
- `/mnt/ssd/kafka/broker-1` -> Mapped to Broker 1 (when scaled)

----

#### Backup & Restore
Since data is stored on the host filesystem, backups can be performed by:
1. Scaling down the StatefulSet to 0.
2. Archiving the `/mnt/ssd/kafka` directory.
3. Scaling back up.
