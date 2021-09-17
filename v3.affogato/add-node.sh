#!/bin/bash
# -----------------------------------------------------------------
source ./env.sh


# -----------------------------------------------------------------
# parameter

# ------------------------------------------------------------------------------
# print info.
echo ""
echo "[INFO]"
echo "- Namespace                  is '${c_NS}'"
echo "- Cluster name               is '${c_CLUSTER}'"
echo "- Connection Ifno.           is '${c_CONFIG}'"
echo "- Spec                       is '${c_SPEC}'"



# ------------------------------------------------------------------------------
# Add Node
(
curl -sX POST ${c_URL_MCKS_NS}/clusters/${c_CLUSTER}/nodes -H "${c_CT}" -d @- <<EOF
{
	"worker": [
		{
			"connection": "${c_CONFIG}",
			"count": 1,
			"spec": "${c_SPEC}"
		}
	]
}
EOF
) | jq

curl -sX GET -H "${c_CT}" ${c_URL_MCKS_NS}/clusters | jq > ./output/clusters.json

# ------------------------------------------------------------------------------
# ssk key, kubeconfig 저장
./save-ssh-kubeconfig.sh
