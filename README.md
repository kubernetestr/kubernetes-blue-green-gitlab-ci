# kubernetes-blue-green-gitlab-ci
Deploying applications with blue green strategy in Kubernetes using Gitlab CI pipelines

bg-deploy.sh <app-name> <deployment.tmpl>

This script creates a new deployment and service in Kubernetes and updates the service with new deployments and deletes old deployments. 

Script has been tested in Gitlab CI and uses git commit hash as Kubernetes deployment version.
