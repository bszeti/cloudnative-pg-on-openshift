# Install operator
oc apply -f deploy-postgresql/subscription.yaml

# User secrets
oc apply -f deploy-postgresql/secret-user-admin.yaml
oc apply -f deploy-postgresql/secret-user-myuser.yaml

# Create instance
oc apply -f deploy-postgresql/pg-cluster.yaml

# Check db
oc exec pg-1 -- /bin/bash -c 'psql postgresql://myuser:mysecret@localhost:5432/db1 <<< "SELECT current_database();"'