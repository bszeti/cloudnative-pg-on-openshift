NAMESPACE=app-postgres
oc new-project $NAMESPACE

# Create ConfigMap with python app
oc delete cm -n $NAMESPACE app; oc create cm -n $NAMESPACE app --from-file=deploy-app/requirements.txt --from-file=deploy-app/postgres-insert.py

# Create Job to run app inserting rows into a PostgreSQL database
oc delete -n $NAMESPACE -f deploy-app/job-postgres-insert.yaml; oc create -n $NAMESPACE -f deploy-app/job-postgres-insert.yaml
oc wait -n $NAMESPACE --for=jsonpath='{.status.ready}'=1 job/postgres-insert
oc logs -n $NAMESPACE -f job/postgres-insert

# oc delete -n app -f deploy-app/job-postgres-insert.yaml
