#!/bin/bash
source ./env.sh

# ------------------------------------------------------------------------------
# print info.
echo ""
echo "[INFO]"
echo "- Namespace                  is '${c_NS}'"
echo "- Cluster name               is '${c_CLUSTER}'"


# ------------------------------------------------------------------------------
curl -sX GET ${c_URL_MCKS_NS}/clusters/${c_CLUSTER} -H "${c_CT}" | jq;
