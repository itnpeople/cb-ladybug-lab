#!/bin/bash
source ./const.env

# ------------------------------------------------------------------------------
# print info.
echo ""
echo "[INFO]"
echo "- Namespace                  is '${c_NS}'"


# ------------------------------------------------------------------------------
curl -sX GET ${c_URL_MCKS_NS}/clusters -H "${c_CT}" | jq;
