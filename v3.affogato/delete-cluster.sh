#!/bin/bash
if [ "$1" != "" ]; then CLUSTER="$1"; fi
source ./env.sh

# ------------------------------------------------------------------------------
# print info.
echo ""
echo "[INFO]"
echo "- Namespace                  is '${c_NS}'"
echo "- Cluster name               is '${c_CLUSTER}'"

# ------------------------------------------------------------------------------
# Delete a cluster
curl -sX DELETE ${c_URL_MCKS_NS}/clusters/${c_CLUSTER}    -H "${c_CT}" | jq;

