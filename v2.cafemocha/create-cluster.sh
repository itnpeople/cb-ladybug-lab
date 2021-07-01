#!/bin/bash
c_NS="acornsoft"
c_URL_SPIDER="http://localhost:1024/spider"
c_URL_TUMBLEBUG="http://localhost:1323/tumblebug"
c_URL_LADYBUG_NS="http://localhost:8080/ladybug/ns/${c_NS}"
c_CT="Content-Type: application/json"
c_AUTH="Authorization: Basic $(echo -n default:default | base64)"

# ------------------------------------------------------------------------------
if [ "$1" != "" ]; then CSP="$1"; fi
if [ "$2" != "" ]; then R="$2"; fi
if [ "${CSP}" == "" ]; then echo "Variable 'CSP' empty"; exit 0; fi
if [ "${R}" == "" ]; then echo "Variable 'R' empty"; exit 0; fi

if [ "${CSP}" == "aws" ];   then SPEC="t2.medium"; fi			#t2.large
if [ "${CSP}" == "gcp" ];   then SPEC="e2-highcpu-4"; fi 		#e2-standard-4
if [ "${CSP}" == "azure" ]; then SPEC="Standard_B2s"; fi

NM_CLUSTER="cb-${CSP}-${R}"
NM_CONFIG="config-${CSP}-${R}"

# ------------------------------------------------------------------------------
# 클러스터 생성
(
curl -sX POST -H "${c_CT}" ${c_URL_LADYBUG_NS}/clusters -d @- <<EOF
{
   "name": "${NM_CLUSTER}",
   "controlPlane": [
      { "connection": "${NM_CONFIG}", "count": 1, "spec": "${SPEC}" }
   ],
   "worker": [
      { "connection": "${NM_CONFIG}", "count": 2, "spec": "${SPEC}" }
    ],
    "config": {
        "kubernetes": {
            "networkCni": "kilo",
            "podCidr": "10.244.0.0/16",
            "serviceCidr": "10.96.0.0/12",
            "serviceDnsDomain": "cluster.local"
        }
    }
}
EOF
)  | jq

curl -sX GET -H "${c_CT}" ${c_URL_LADYBUG_NS}/clusters | jq > ./output/clusters.json


# ------------------------------------------------------------------------------
# ssk key, kubeconfig 저장
./save-ssh-kubeconfig.sh "${CSP}" "${R}"
