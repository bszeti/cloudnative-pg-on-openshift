NAMESPACE=postgres
oc delete -n $NAMESPACE -f load-data/job-load-data.yaml; oc create -n $NAMESPACE -f load-data/job-load-data.yaml
oc wait -n $NAMESPACE --for=jsonpath='{.status.ready}'=1 job/load-data
oc logs -n $NAMESPACE -f job/load-data
