#!/bin/bash
# -----------------------------------------------------------------
if [ "$1" != "" ]; then CSP="$1"; fi
if [ "$2" != "" ]; then R="$2"; fi
if [ "${CSP}" == "" ]; then echo "Variable 'CSP' is empty"; exit 0; fi
if [ "${R}" == "" ]; then echo "Variable 'R' is empty"; exit 0; fi

c_CT="Content-Type: application/json"
c_AUTH="Authorization: Basic $(echo -n default:default | base64)"
c_CONFIG="config-${CSP}-${R}"
c_CLUSTER="cb-cluster"
c_SSHKEY="${CSP}-${R}-sshkey"
c_NS="acornsoft"
c_URL_TUMBLEBUG="http://localhost:1323/tumblebug"
c_URL_MCKS="http://localhost:1470/mcks"

# ------------------------------------------------------------------------------
rm -f ssh/${CSP}-${R}.pem
curl -sX GET ${c_URL_TUMBLEBUG}/ns/${c_NS}/resources/sshKey/${c_SSHKEY}  -H "${c_AUTH}" -H "${c_CT}" -d "{\"connectionName\" : \"${c_CONFIG}\"}" | jq -r ".privateKey" > ssh/${CSP}-${R}.pem
chmod 400 ssh/${CSP}-${R}.pem
cat ssh/${CSP}-${R}.pem

rm -f kubeconfig/${c_CLUSTER}.yaml
curl -sX GET ${c_URL_MCKS}/ns/${c_NS}/clusters/${c_CLUSTER} | jq -r ".clusterConfig" > kubeconfig/${c_CLUSTER}.yaml
curl -sX GET ${c_URL_MCKS}/ns/${c_NS}/clusters/${c_CLUSTER} | jq -r ".nodes[].publicIp"

echo ""
echo "ssh -i ./ssh/${CSP}-${R}.pem cb-user@"
echo "export KUBECONFIG=$(pwd)/kubeconfig/${c_CLUSTER}.yaml"