#!/bin/bash
set -x
printf "Starting to install components...\n\n"

kubectl apply -f kubernetes/clusterrole.yaml 
kubectl apply -f kubernetes/serviceaccount.yaml
kubectl apply -f kubernetes/clusterrolebinding.yaml 
kubectl apply -f kubernetes/service.yaml 
kubectl apply -f kubernetes/deployment.yaml 
kubectl apply -f kubernetes/mutating-webhook-configuration.yaml 
kubectl create -f kubernetes/configmap-sidecar-test.yaml

printf "\n All components added...\n"
exit 0