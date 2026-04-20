APP_NAMESPACE=app-postgres
oc new-project $APP_NAMESPACE

# Create ConfigMap with python app
oc delete cm -n $APP_NAMESPACE app; oc create cm -n $APP_NAMESPACE app --from-file=deploy-app/requirements.txt --from-file=deploy-app/postgres-insert.py

# Create Job to run app inserting rows into a PostgreSQL database
oc delete -n $APP_NAMESPACE -f deploy-app/job-postgres-insert.yaml; oc create -n $APP_NAMESPACE -f deploy-app/job-postgres-insert.yaml
oc wait -n $APP_NAMESPACE --for=jsonpath='{.status.ready}'=1 job/postgres-insert
oc logs -n $APP_NAMESPACE -f job/postgres-insert

# oc delete -n app -f deploy-app/job-postgres-insert.yaml
