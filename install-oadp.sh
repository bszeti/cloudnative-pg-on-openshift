OPERATOR_OADP_NAMESPACE=openshift-adp
NAMESPACE=postgres

# Install operator
oc apply -n $OPERATOR_OADP_NAMESPACE -f backup-oadp/subscription.yaml

# Create GCP secret
oc apply -n $OPERATOR_OADP_NAMESPACE -f backup-oadp/secret-gcp-credentials.yaml

# Setup backup locations
oc apply -n $OPERATOR_OADP_NAMESPACE -f backup-oadp/dataprotectionapplication.yaml
# oc apply -n $OPERATOR_OADP_NAMESPACE -f backup-oadp/dataprotectionapplication-multiple.yaml

# Run backup on database
primary_pod=$(oc get -n $NAMESPACE -oname pod --selector='role=primary')
replica_pod=$(oc get -n $NAMESPACE -oname pod --selector='role=replica')
echo "Set orderedResources.pods: $NAMESPACE/$(basename $replica_pod),$NAMESPACE/$(basename $primary_pod)"
# Using generateName for Backup, as it must be unique
oc create -n $OPERATOR_OADP_NAMESPACE -f backup-oadp/backup.yaml
# Creates resources backup at gs://my-bucket-n9dps/cloudnative-pg-oadp/backups/test-abc12/
# Backups must be deleted in Object Storage, not in OpenShift, otherwise the operator recreates them

# Run restore
oc delete project $NAMESPACE
oc delete -n $OPERATOR_OADP_NAMESPACE -f backup-oadp/restore.yaml
oc create -n $OPERATOR_OADP_NAMESPACE -f backup-oadp/restore.yaml
# Wait for namespace and pods
until oc get namespace $NAMESPACE && oc get -n $NAMESPACE pod/pg-1 && oc get -n $NAMESPACE pod/pg-2; do
    sleep 1
done
oc wait -n $NAMESPACE --for=condition=Ready pod/pg-1
oc wait -n $NAMESPACE --for=condition=Ready pod/pg-2

# Delete VolumeSnapshots afterwards, because otherwise they are included in next backup, which is confusing
oc delete -n $NAMESPACE volumesnapshots --all

# VolumeSnapshotContents will still stay, because Velero sets "deletionPolicy: Retain ", but their name matches the VolumeSnapshots
vsclist=$(oc get -n $NAMESPACE -oname volumesnapshots)
for vsc in $vsclist; do
  oc delete VolumeSnapshotContent $(basename $vsc)
done
# The backend snapshot is still NOT removed! That needs a backend specific retention process or policy