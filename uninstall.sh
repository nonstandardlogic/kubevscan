#!/bin/bash
set +x

echo "Starting to uninstall components..."

kubectl delete pod debian-debug 
kubectl delete secrets k8s-sidecar-injector --namespace=kube-system

echo "All components related to k8s-sidecar-injector have been removed."
echo "Please uninstall the Helm distribution"

exit 0