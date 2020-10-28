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

ORG="nonstandardlogic"
DOMAIN="nonstandardlogic.com"
DEPLOYMENT="london"
CLUSTER="DEV"

export ORG
export DOMAIN
export DEPLOYMENT
export CLUSTER

cd "$TLS_DIR" || { printf "Failure to cd to %s \n" "$TLS_DIR" ; exit 1; }

printf "Set required variables in tca.conf csr-prod.conf..\n"
cp -f "$TLS_DIR"/source/*.* "${TLS_DIR}"
sed -i -e "s|__ORG__|$ORG|g" -e "s|__DOMAIN__|$DOMAIN|g" ca.conf

printf "Generating certs..\n"
$TLS_DIR/new-cluster-injector-cert.rb

printf "Generating CA Bundle value..\n"
CABUNDLE_BASE64="$(cat $TLS_DIR/$DEPLOYMENT/$CLUSTER/ca.crt |base64|tr -d '\n')"


cd "$K8S_DIR" || { printf "Failure to cd to %s \n" "$K8S_DIR" ; exit 1; }

printf "Set required variables in mutating-webhook-configuration.yaml..\n"
p -f "$K8S_DIR"/source/*.* "${K8S_DIR}"
sed -i -e "s|__CA_BUNDLE_BASE64__|$CABUNDLE_BASE64|g"  mutating-webhook-configuration.yaml 

# Helm Script



printf "Kubevscan deployment completed...\n"
exit 0