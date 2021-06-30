#!/bin/bash
c_URL_SPIDER="http://localhost:1024/spider"
c_URL_TUMBLEBUG="http://localhost:1323/tumblebug"
c_NS="cb-${CSP}-namespace"
c_URL_LADYBUG_NS="http://localhost:8080/ladybug/ns/${c_NS}"
c_CT="Content-Type: application/json"
c_AUTH="Authorization: Basic $(echo -n default:default | base64)"

# ------------------------------------------------------------------------------
post() {

# 클러스터 생성
(
curl -sX POST -H "${c_CT}" ${c_URL_LADYBUG_NS}/clusters -d @- <<EOF
{
   "name": "cb-${CSP}-${R}",
   "controlPlane": [
      { "connection": "cb-${CSP}-${R}-config", "count": 1, "spec": "${SPEC}" }
   ],
   "worker": [
      { "connection": "cb-${CSP}-${R}-config", "count": 2, "spec": "${SPEC}" }
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

rm -f ssh/${CSP}-${R}.pem
curl -sX GET ${c_URL_TUMBLEBUG}/ns/${c_NS}/resources/sshKey/cb-${CSP}-${R}-config-sshkey   -H "${c_AUTH}" -H "${c_CT}" -d "{\"connectionName\" : \"cb-${CSP}-${R}-config\"}" | jq -r ".privateKey" > ssh/${CSP}-${R}.pem
chmod 400 ssh/${CSP}-${R}.pem
cat ssh/${CSP}-${R}.pem

rm -f kubeconfig/${CSP}-${R}.yaml
curl -sX GET ${c_URL_LADYBUG_NS}/clusters/cb-${CSP}-${R} | jq -r ".clusterConfig" > kubeconfig/${CSP}-${R}.yaml

}

# ------------------------------------------------------------------------------
if [ "$1" != "" ]; then CSP="$1"; fi
if [ "$2" != "" ]; then R="$2"; fi
if [ "${CSP}" == "" ]; then echo "Variable 'CSP' empty"; exit 0; fi
if [ "${R}" == "" ]; then echo "Variable 'R' empty"; exit 0; fi

c_CSP_UPPER="$(echo ${CSP} | tr [:lower:] [:upper:])"

if [ "${CSP}" == "aws" ];   then SPEC="t2.medium"; fi			#t2.large
if [ "${CSP}" == "gcp" ];   then SPEC="e2-highcpu-4"; fi 		#e2-standard-4
if [ "${CSP}" == "azure" ]; then SPEC="Standard_B2s"; fi

post;


