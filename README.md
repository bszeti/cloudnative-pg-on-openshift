# Cloudnative PG Operator on Red Hat OpenShift

# Backup with OpenShift ADP

Known Issues:
- The backup pre-hook running `pg_backup_start()` results a zombie process in the Pod.
- Backup order for volumes must be "replica" then "primary" to avoid timeline conflict after restore.
- Deleting the Backups manually (in Object Storage) doesn't remove the related snapshots - as that info was stored there. Meanwhile it's done properly when the Backup expires (checked every 1 hour by default).

- The VolumeSnapshots and related VolumeSnapshotContents are left in the namespace after Restore. Delete them before taking a next Backup, otherwise they start piling up.

