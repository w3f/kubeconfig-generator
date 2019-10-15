#!/bin/bash

set -euxo pipefail

export USER=${1:-user}
export ORG=${2:-org}
export ROLE=${3:-view}
export CSR_NAME=${4:-mycsr}

kubectl delete clusterrolebinding ${ROLE} || true
kubectl delete csr ${CSR_NAME} || true

rm -rf build && mkdir build

openssl genrsa -out ./build/${USER}.key 4096

cat csr.tpl | envsubst > ./build/csr.cnf

openssl req -config ./build/csr.cnf -new -key ./build/${USER}.key -nodes -out ./build/${USER}.csr

export BASE64_CSR=$(cat ./build/${USER}.csr | base64 | tr -d '\n')

cat csr_resource.yaml.tpl | envsubst | kubectl apply -f -

kubectl certificate approve ${CSR_NAME}

cat clusterrolebinding.tpl | envsubst | kubectl apply -f -

export CLUSTER_NAME=$(kubectl config view --minify -o jsonpath={.current-context})
export CLIENT_CERTIFICATE_DATA=$(kubectl get csr ${CSR_NAME} -o jsonpath='{.status.certificate}')
export CLUSTER_CA=$(kubectl config view --raw -o json | jq -r '.clusters[] | select(.name == "'$(kubectl config current-context)'") | .cluster."certificate-authority-data"')
export CLUSTER_ENDPOINT=$(kubectl config view --raw -o json | jq -r '.clusters[] | select(.name == "'$(kubectl config current-context)'") | .cluster."server"')
export CLIENT_KEY_DATA=$(cat ./build/${USER}.key | base64 | tr -d '\n')

cat kubeconfig.tpl | envsubst > ./build/kubeconfig
