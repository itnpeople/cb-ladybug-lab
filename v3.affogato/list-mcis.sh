#!/bin/bash
# ------------------------------------------------------------------------------
source ./const.env

# ------------------------------------------------------------------------------
# print info.
echo ""
echo "[INFO]"
echo "- Namespace                  is '${c_NS}'"


# ------------------------------------------------------------------------------
# show init result
curl -sX GET ${c_URL_TUMBLEBUG_NS}/resources/securityGroup	-H "${c_AUTH}" 	-H "${c_CT}" | jq;
#curl -sX GET ${c_URL_TUMBLEBUG_NS}/mcis -H "${c_AUTH}" -H "${c_CT}" | jq;

