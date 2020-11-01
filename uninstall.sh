#!/bin/bash
set +x

echo "Starting to uninstall components..."

kubectl delete serviceaccount k8s-sidecar-injector -n kube-system
kubectl delete service k8s-sidecar-injector-prod -n kube-system
kubectl delete MutatingWebhookConfiguration tumblr-sidecar-injector-webhook
kubectl delete deployment k8s-sidecar-injector-prod -n kube-system
kubectl delete pod debian-debug 
kubectl delete configmap test-config
kubectl delete configmap sidecar-test -n kube-system
kubectl delete clusterroleBinding k8s-sidecar-injector
kubectl delete clusterrole k8s-sidecar-injector
kubectl delete secrets k8s-sidecar-injector --namespace=kube-system

echo "All components related to k8s-sidecar-injector have been removed."
echo "Please uninstall the Helm distribution"

exit 0