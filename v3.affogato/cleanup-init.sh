#!/bin/bash
# ------------------------------------------------------------------------------
source ./env.sh
source ./credential.sh

if [ "${c_REGION}" == "" ]; then echo "Variable 'c_REGION' is mandatory"; exit 0; fi
if [ "${c_ZONE}" == "" ]; then echo "Variable 'c_ZONE' is mandatory"; exit 0; fi


NM_DRIVER="${CSP}-driver-v1.0"
NM_REGION="region-${CSP}-${R}"
NM_CREDENTIAL="credential-${CSP}-${R}"

curl -sX DELETE -H "${c_CT}" ${c_URL_SPIDER}/driver/${CSP}-driver-v1.0
curl -sX DELETE -H "${c_CT}" ${c_URL_SPIDER}/region/region-${CSP}-${R}
curl -sX DELETE -H "${c_CT}" ${c_URL_SPIDER}/credential/${NM_CREDENTIAL}
curl -sX DELETE -H "${c_CT}" -H "${c_AUTH}" ${c_URL_SPIDER}/connectionconfig/${c_CONFIG}
curl -sX DELETE -H "${c_AUTH}" -H "${c_CT}" ${c_URL_TUMBLEBUG}/ns/${c_NS}
