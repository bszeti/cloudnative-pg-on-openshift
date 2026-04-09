OPERATOR_PG_NAMESPACE=cloudnative-pg-operator
NAMESPACE=postgres

# Install operator
oc apply -n $OPERATOR_PG_NAMESPACE -f deploy-postgresql/subscription.yaml

oc new-project $NAMESPACE
# User secrets
oc apply -n $NAMESPACE -f deploy-postgresql/secret-user-admin.yaml
oc apply -n $NAMESPACE -f deploy-postgresql/secret-user-myuser.yaml

# Create instance
oc apply -n $NAMESPACE -f deploy-postgresql/pg-cluster.yaml

# Use db as admin
oc exec -n $NAMESPACE pg-1 -- /bin/bash -c 'psql -U postgres db1 -c "SELECT current_database();"'
oc exec -n $NAMESPACE pg-1 -- /bin/bash -c 'psql -U postgres db1 -c "\dt *.*"'
oc exec -n $NAMESPACE pg-1 -- /bin/bash -c 'psql -U postgres db1 -c "
        CREATE TABLE messages (
          id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
          created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
          message VARCHAR(1000)
        );"'
oc exec -n $NAMESPACE pg-1 -- /bin/bash -c 'psql -U postgres db1 -c "INSERT INTO messages (message) VALUES ('\''hello1'\'');"'
oc exec -n $NAMESPACE pg-1 -- /bin/bash -c 'psql -U postgres db1 -c "select * from messages;"'

# Use db as user. It can't access tables created by admin by default.
oc exec -n $NAMESPACE pg-1 -- /bin/bash -c 'psql postgresql://myuser:mysecret@localhost:5432/db1 <<< "
        CREATE TABLE mymessages (
          id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
          created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
          message VARCHAR(1000)
        );"'

oc exec -n $NAMESPACE pg-1 -- /bin/bash -c 'psql postgresql://myuser:mysecret@localhost:5432/db1 <<< "select * from mymessages;"'

