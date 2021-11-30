#!/bin/bash
# -----------------------------------------------------------------
source ./env.sh

# ------------------------------------------------------------------------------

NM_SSHKEY="${CSP}-${R}-sshkey"

if [ "${CSP}" == "tencent" ]; then 
	NM_SSHKEY=$(echo ${NM_SSHKEY} | sed -e 's/-//g')
fi

rm -f ssh/${c_CLUSTER}.pem
curl -sX GET ${c_URL_TUMBLEBUG}/ns/${c_NS}/resources/sshKey/${NM_SSHKEY}  -H "${c_AUTH}" -H "${c_CT}" -d "{\"connectionName\" : \"${c_CONFIG}\"}" | jq -r ".privateKey" > ssh/${c_CLUSTER}.pem
chmod 400 ssh/${c_CLUSTER}.pem
cat ssh/${c_CLUSTER}.pem

rm -f kubeconfig/${c_CLUSTER}.yaml
curl -sX GET ${c_URL_MCKS_NS}/clusters/${c_CLUSTER} | jq -r ".clusterConfig" > kubeconfig/${c_CLUSTER}.yaml
curl -sX GET ${c_URL_MCKS_NS}/clusters/${c_CLUSTER} | jq -r ".nodes[].publicIp"

echo ""
echo "ssh -i ./ssh/${c_CLUSTER}.pem cb-user@"
echo "export KUBECONFIG=$(pwd)/kubeconfig/${c_CLUSTER}.yaml"