#!/bin/bash
# -----------------------------------------------------------------
source ./env.sh

# ------------------------------------------------------------------------------

NM_SSHKEY="${CSP}-${R}-sshkey"

if [ "${CSP}" == "tencent" ]; then 
	NM_SSHKEY=$(echo ${NM_SSHKEY} | sed -e 's/-//g')
fi

rm -f ssh/${NM_SSHKEY}.pem
curl -sX GET ${c_URL_TUMBLEBUG}/ns/${c_NS}/resources/sshKey/${NM_SSHKEY}  -H "${c_AUTH}" -H "${c_CT}" -d "{\"connectionName\" : \"${c_CONFIG}\"}" | jq -r ".privateKey" > ssh/${NM_SSHKEY}.pem
chmod 400 ssh/${NM_SSHKEY}.pem
cat ssh/${NM_SSHKEY}.pem

rm -f kubeconfig/${c_CLUSTER}.yaml
curl -sX GET ${c_URL_MCKS_NS}/clusters/${c_CLUSTER} | jq -r ".clusterConfig" > kubeconfig/${c_CLUSTER}.yaml
curl -sX GET ${c_URL_MCKS_NS}/clusters/${c_CLUSTER} | jq -r ".nodes[].publicIp"

echo ""
echo "ssh -i ./ssh/${c_CLUSTER}.pem cb-user@"
echo "export KUBECONFIG=$(pwd)/kubeconfig/${c_CLUSTER}.yaml"