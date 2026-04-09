# Cloudnative PG Operator on Red Hat OpenShift

# Backup with OpenShift ADP

Known Issues:
- The backup pre-hook running `pg_backup_start()` results a zombie process in the Pod.
- Backup order for volumes should be "replica" then "primary" to avoid timeline conflict after restore. The `orderedResources` field supports names only, not labels, so we have to query first which Pod is which one at the time of the Backup.
- The VolumeSnapshotContents are deleted after taking a Backup, but the backing CSI snapshots stay there forever. Requires an independent retention process/policy.
- The VolumeSnapshots are left in the namespace after Restore. Delete them before taking a next Backup, otherwise they start piling up.