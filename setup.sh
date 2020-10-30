#!/bin/bash
#
# The script deploys the kubevscan service to the K8S cluster.
#
###
# General remarks
#
# * The following software must be installed before the execution of this script: 
# * Ruby, Kubectl, Helm and AWS CLI.
##

set -x

printf "Starting to deploy components...\n\n"

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR=${BASE_DIR}/config
TLS_DIR=${CONFIG_DIR}/tls
K8S_DIR=${BASE_DIR}/kubernetes
HELM_DIR=${BASE_DIR}/helm

ORG="nonstandardlogic"
DOMAIN="nonstandardlogic.com"
DEPLOYMENT="london"
CLUSTER="DEV"

export ORG
export DOMAIN
export DEPLOYMENT
export CLUSTER

cd "$TLS_DIR" || { printf "Failure to cd to %s \n" "$TLS_DIR" ; exit 1; }

printf "Set required variables in ca.conf csr-prod.conf..\n"

if [ ! -f "$TLS_DIR"/source/ca.conf ]; then
    printf "original ca.conf not found!\n"
    exit 1
fi

if [ ! -f "$TLS_DIR"/source/csr-prod.conf ]; then
    printf "original ca.conf not found!\n"
    exit 1
fi

cp -f "$TLS_DIR"/source/ca.conf "${TLS_DIR}"
cp -f "$TLS_DIR"/source/csr-prod.conf "${TLS_DIR}"
sed -i -e "s|__ORG__|$ORG|g" -e "s|__DOMAIN__|$DOMAIN|g" ca.conf csr-prod.conf

printf "Generating certs..\n"
$TLS_DIR/new-cluster-injector-cert.rb

printf "Generating CA Bundle value..\n"
CABUNDLE_BASE64="$(cat $TLS_DIR/$DEPLOYMENT/$CLUSTER/ca.crt |base64|tr -d '\n')"

cd "$K8S_DIR" || { printf "Failure to cd to %s \n" "$K8S_DIR" ; exit 1; }

if [ ! -f "$K8S_DIR"/source/mutating-webhook-configuration.yaml ]; then
    printf "original mutating-webhook-configuration.yaml not found!\n"
    exit 1
fi

printf "Set required variables in mutating-webhook-configuration.yaml..\n"
cp -f "$HELM_DIR"/kubevscan/src/values.yaml "${HELM_DIR}"/kubevscan/
sed -i -e "s|__CA_BUNDLE_BASE64__|$CABUNDLE_BASE64|g"  "${HELM_DIR}"/kubevscan/values.yaml

printf "Set secrets..\n"
kubectl create secret generic k8s-sidecar-injector --from-file=$TLS_DIR/${DEPLOYMENT}/${CLUSTER}/sidecar-injector.crt --from-file=$TLS_DIR/${DEPLOYMENT}/${CLUSTER}/sidecar-injector.key --namespace=kube-system

# Helm Script
cd "$HELM_DIR" || { printf "Failure to cd to %s \n" "$HELM_DIR" ; exit 1; }
printf "Distribution name: "
read DISTRIBUTION
helm install $DISTRIBUTION ./kubevscan

printf "\n Kubevscan deployment completed..\n"
exit 0