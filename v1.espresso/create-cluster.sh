#!/bin/bash
c_URL_SPIDER="http://localhost:1024/spider"
c_URL_TUMBLEBUG="http://localhost:1323/tumblebug"
c_NS="cb-${CSP}-namespace"
c_URL_LADYBUG_NS="http://localhost:8080/ladybug/ns/${c_NS}"
c_CT="Content-Type: application/json"
c_AUTH="Authorization: Basic $(echo -n default:default | base64)"

# ------------------------------------------------------------------------------
post() {

# Conn. info 등록
curl -sX DELETE -H "${c_CT}" -H "${c_AUTH}" -H "${c_AUTH}" ${c_URL_TUMBLEBUG}/ns/${c_NS}/mcis/cb-${R}
curl -sX DELETE -H "${c_CT}" -H "${c_AUTH}" -H "${c_AUTH}" ${c_URL_SPIDER}/connectionconfig/cb-aws-config
curl -sX POST   -H "${c_CT}" -H "${c_AUTH}" ${c_URL_SPIDER}/connectionconfig -d @- <<EOF
{
	"ConfigName"     : "cb-${CSP}-config",
	"ProviderName"   : "${c_CSP_UPPER}", 
	"DriverName"     : "${CSP}-driver-v1.0", 
	"CredentialName" : "credential-${CSP}-${R}", 
	"RegionName"     : "region-${CSP}-${R}"
}
EOF

# 클러스터 생성
(
curl -sX POST -H "${c_CT}" ${c_URL_LADYBUG_NS}/clusters -d @- <<EOF
{
	"name"                  : "cb-${CSP}-${R}",
	"controlPlaneNodeCount" : 1,
	"controlPlaneNodeSpec"  : "${SPEC}",
	"workerNodeCount"       : 2,
	"workerNodeSpec"        : "${SPEC}"
}
EOF
)  | jq

rm -f ssh/${CSP}-${R}.pem
curl -sX GET ${c_URL_TUMBLEBUG}/ns/${c_NS}/resources/sshKey/cb-${CSP}-${R}-sshkey   -H "${c_AUTH}" -H "${c_CT}" -d "{\"connectionName\" : \"cb-${CSP}-config\"}" | jq -r ".privateKey" > ssh/${CSP}-${R}.pem
chmod 400 ssh/${CSP}-${R}.pem
cat ssh/${CSP}-${R}.pem

rm -f kubeconfig/${CSP}-${R}.yaml
curl -sX GET ${c_URL_LADYBUG_NS}/clusters/cb-${CSP}-${R} | jq -r ".clusterConfig" > kubeconfig/${CSP}-${R}.yaml

}

# ------------------------------------------------------------------------------

if [ "${R}" == "" ]; then echo "Variable 'R' empty"; exit 0; fi
if [ "${CSP}" == "" ]; then echo "Variable 'CSP' empty"; exit 0; fi

c_CSP_UPPER="$(echo ${CSP} | tr [:lower:] [:upper:])"

if [ "${CSP}" == "aws" ]; then 
	# image 삭제
	curl -sX DELETE -H "${c_CT}" -H "${c_AUTH}" -H "${c_AUTH}" ${c_URL_TUMBLEBUG}/ns/${c_NS}/resources/image/cb-${CSP}-config-Ubuntu1804
	SPEC="t2.medium"
fi

if [ "${CSP}" == "gcp" ]; then 
	#SPEC="e2-standard-4"
	SPEC="e2-highcpu-4"
fi

post;


