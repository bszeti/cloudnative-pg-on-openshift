# CloudNativePG Operator on Red Hat OpenShift

In this repo we use the [CloudNativePG](https://cloudnative-pg.io/) operator to manage PostgreSQL database on [Red Hat OpenShift v4](https://www.redhat.com/en/technologies/cloud-computing/openshift).

To deploy the operator (`v1.29.0`) and create a Postgres instance with replica see [install-postgres.sh](./install-postgres.sh) and related `Cluster` [resource](./deploy-postgresql/pg-cluster.yaml).

## Test apps

A simple Python test app can be found in [deploy-app](./deploy-app) folder, see [install-app.sh](./install-app.sh) to run it as a Kubernetes job. This app is useful to generate ongoing traffic meanwhile taking a backup and see what was included.

Main env vars:
- **MESSAGE_LENGTH**: Length of string to insert into a table row
- **BATCH_SIZE**: Number of rows to insert in one batch (transaction)
- **BATCH_COUNT**: Number of rounds, the Job is finished afterwards
- **SLEEP_MS**: Sleep time between rounds

## Load high volume of data

This [Job](./load-data/job-load-data.yaml) and related [load-data.sh](./load-data.sh) can be used to generate multiple gigabytes of data in a table. This is useful to test backup of large databases.

Main env vars:
- **DATA_SIZE_GB**: How many GBs of data do we want inject into the database

## Backup with OpenShift ADP

The [backup-oadp](./backup-oadp) folder and related [install-oadp.sh](./install-oadp.sh) shows how to create a backup of our database with [Red Hat OpenShift APIs for Data Protection (OADP)](https://docs.redhat.com/en/documentation/openshift_container_platform/4.21/html/backup_and_restore/oadp-application-backup-and-restore) which is a generic Kubernetes native backup solution based on the [Velero](https://velero.io/) tool.

This example uses [Google Cloud Object Storage](https://cloud.google.com/storage) to store K8s resources, while utilizes the cluster's CSI driver to create [VolumeSnapshots](https://kubernetes.io/docs/concepts/storage/volume-snapshots/) of the `PersistentVolumes`. See the `DataProtectionApplication` examples how to configure one or multiple backup locations.

There are too `Backup` examples here:
- `backup-exclude-replica.yaml` (recommended): Creating a snapshot only of the `primary` node. During restore the operator takes care of creating the `replica` instance by creating a full copy of the database. This takes time, but the `primary` is still usable during this period. (10GB data took ~15mins)
- `backup-both-pods.yaml`: Creating volume snapshots from both `primary` and `secondary`. It's important to make sure that a snapshot is taken from the `replica` instance first, otherwise we'll get timeline conflict after restore breaking the replication. The order can be set in `orderedResources.pods` field, but first we need to query somehow which *Pod* is having which role at the moment of the backup, which makes the solution more complicated. The advantage is that "full replication" state can be achieved quicker after restore, because the `replica` doesn't start with a full sync.

With the tested [OADP version](https://github.com/openshift/oadp-operator#velero-version-relationship) (`v1.5` on OpenShift `v4.21`) we noticed that the restored `VolumeSnapshot` resources are kept in the namespace after the related `PersistentVolumes` are restored. This is confusing when we're trying to make backups again of the restored namespace, and it's recommended to be deleted once we verified that the restore was successful (e.g. the Pods reached `Ready`). Deleting the `VolumeSnapshot` won't remove the actual snapshot in the backend, those are only removed when the `Backup` expires.

See [restore.yaml](backup-oadp/restore.yaml) how to restore an existing `Backup`. Set `namespaceMapping` to restore in another namespace.

Notes and Known Issues:
- A backup pre-hook is required to run `pg_backup_start()` before taking a snapshot to guarantee database level file consistency. This `psql` session must be running after the hook is completed, otherwise the backup status will be aborted. In this example we assume 60sec is enough for the CSI driver to create a snapshot before calling `pg_backup_stop()`. The apps can still use the database during this timeframe.
- The backup pre-hook running `pg_backup_start()` must be put in background, which results a zombie process in the Pod.
- Deleting the backups manually (in Object Storage) doesn't remove the related snapshots - as that info was stored there. Meanwhile it's done properly when the `Backup` expires (checked every 1 hour by default).
- The `VolumeSnapshots` (and related `VolumeSnapshotContents`) are left in the namespace after Restore. Delete them before taking a next Backup, otherwise they start piling up.


See https://developers.redhat.com/articles/2025/12/23/getting-started-openshift-apis-data-protection about `NonAdminBackups`.
