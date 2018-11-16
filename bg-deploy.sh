#!/bin/bash

# bg-deploy.sh <app-name> <deployment.tmpl>
set -eux

APP_NAME=$1
VERSION=$CI_COMMIT_SHA
DEPLOYMENTFILE=$2
NAMESPACE=web
DEPLOYMENTNAME=$APP_NAME-$VERSION

cat $DEPLOYMENTFILE > deployment-$VERSION.yml

sed -i "s/VERSION/$CI_COMMIT_SHA/g" deployment-$VERSION.yml
sed -i "s/APP_NAME/$APP_NAME/g" deployment-$VERSION.yml

# Deploy app
kubectl apply -f deployment-$VERSION.yml

# Deployment manifest is no longer needed.
rm deployment-$VERSION.yml

# Wait until the Deployment is ready by checking the MinimumReplicasAvailable condition.
READY=$(kubectl get deploy $DEPLOYMENTNAME -n $NAMESPACE -o json | jq '.status.conditions[] | select(.reason == "MinimumReplicasAvailable") | .status' | tr -d '"')
while [[ "$READY" != "True" ]]; do
    READY=$(kubectl get deploy $DEPLOYMENTNAME -n $NAMESPACE -o json | jq '.status.conditions[] | select(.reason == "MinimumReplicasAvailable") | .status' | tr -d '"')
    sleep 5
done

# If service exists, patch it. If not, create it.
if kubectl get svc -n $NAMESPACE $APP_NAME ; then
    kubectl patch svc -n $NAMESPACE $APP_NAME -p "{\"spec\":{\"selector\": {\"app\": \"${APP_NAME}\", \"version\": \"${VERSION}\"}}}"
    kubectl patch svc -n $NAMESPACE $APP_NAME -p "{\"metadata\":{\"labels\": {\"app\": \"${APP_NAME}\", \"version\": \"${VERSION}\"}}}"
else
    kubectl expose deployment $DEPLOYMENTNAME --type=NodePort --name=$APP_NAME -n $NAMESPACE
fi
