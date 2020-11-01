#!/bin/bash
set -x
printf "Starting to uninstall components...\n\n"

kubectl delete pod debian-debug 
kubectl delete secrets k8s-sidecar-injector --namespace=kube-system

printf "\n All components removed...\n"
exit 0