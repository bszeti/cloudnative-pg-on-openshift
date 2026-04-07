OPERATOR_NAMESPACE=openshift-adp
# Install operator
oc apply -n $OPERATOR_NAMESPACE -f backup-oadp/subscription.yaml

# Create GCP secret
oc apply -n $OPERATOR_NAMESPACE -f backup-oadp/secret-gcp-credentials.yaml

# Setup backup locations
oc apply -n $OPERATOR_NAMESPACE -f backup-oadp/dataprotectionapplication.yaml
# oc apply -n $OPERATOR_NAMESPACE -f backup-oadp/dataprotectionapplication-multiple.yaml

# Run backup
# oc delete -n $OPERATOR_NAMESPACE -f backup-oadp/backup.yaml
oc create -n $OPERATOR_NAMESPACE -f backup-oadp/backup.yaml
# Creates resources backup at gs://my-bucket-n9dps/cloudnative-pg-oadp/backups/test-postgres-backup/
