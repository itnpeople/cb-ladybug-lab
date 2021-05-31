#!/bin/bash
c_URL_LADYBUG_NS="http://localhost:8080/ladybug/ns/cb-${CSP}-namespace"
c_CT="Content-Type: application/json"


if [ "${R}" == "" ]; then echo "Variable 'R' empty"; exit 0; fi
if [ "${CSP}" == "" ]; then echo "Variable 'CSP' empty"; exit 0; fi


# ------------------------------------------------------------------------------
# 클러스터 삭제 
curl -sX DELETE -H "${c_CT}" ${c_URL_LADYBUG_NS}/clusters/cb-${CSP}-${R};

# ------------------------------------------------------------------------------
# 결과확인
echo "# ------------------------------------------------------------------------------"
curl -sX GET http://localhost:8080/ladybug/ns/cb-${CSP}-namespace/clusters | jq