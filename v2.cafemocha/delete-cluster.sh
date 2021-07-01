#!/bin/bash
c_NS="acornsoft"
c_URL_LADYBUG_NS="http://localhost:8080/ladybug/ns/${c_NS}"
c_CT="Content-Type: application/json"

if [ "$1" != "" ]; then CSP="$1"; fi
if [ "$2" != "" ]; then R="$2"; fi
if [ "${CSP}" == "" ]; then echo "Variable 'CSP' empty"; exit 0; fi
if [ "${R}" == "" ]; then echo "Variable 'R' empty"; exit 0; fi

NM_CLUSTER="cb-${CSP}-${R}"

# ------------------------------------------------------------------------------
# 클러스터 삭제 
curl -sX DELETE -H "${c_CT}" ${c_URL_LADYBUG_NS}/clusters/${NM_CLUSTER};

# ------------------------------------------------------------------------------
# 결과확인
echo "# ------------------------------------------------------------------------------"
curl -sX GET ${c_URL_LADYBUG_NS}/clusters | jq