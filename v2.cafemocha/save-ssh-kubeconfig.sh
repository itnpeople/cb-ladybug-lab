#!/bin/bash
# ------------------------------------------------------------------------------
if [ "$1" != "" ]; then CSP="$1"; fi
if [ "$2" != "" ]; then R="$2"; fi
if [ "${CSP}" == "" ]; then echo "Variable 'CSP' empty"; exit 0; fi
if [ "${R}" == "" ]; then echo "Variable 'R' empty"; exit 0; fi


c_NS="acornsoft"
c_URL_TUMBLEBUG="http://localhost:1323/tumblebug"
c_URL_LADYBUG_NS="http://localhost:8080/ladybug/ns/${c_NS}"
c_CT="Content-Type: application/json"
c_AUTH="Authorization: Basic $(echo -n default:default | base64)"

NM_SSHKEY="cb-${CSP}-${R}-config-sshkey"
NM_CONFIG="config-${CSP}-${R}"

rm -f ssh/${CSP}-${R}.pem
curl -sX GET ${c_URL_TUMBLEBUG}/ns/${c_NS}/resources/sshKey/${CSP}-${R}-sshkey  -H "${c_AUTH}" -H "${c_CT}" -d "{\"connectionName\" : \"${NM_CONFIG}\"}" | jq -r ".privateKey" > ssh/${CSP}-${R}.pem
chmod 400 ssh/${CSP}-${R}.pem
cat ssh/${CSP}-${R}.pem

rm -f kubeconfig/${CSP}-${R}.yaml
curl -sX GET ${c_URL_LADYBUG_NS}/clusters/cb-${CSP}-${R} | jq -r ".clusterConfig" > kubeconfig/${CSP}-${R}.yaml
