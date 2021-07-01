#!/bin/bash
c_NS="acornsoft"
c_URL_SPIDER="http://localhost:1024/spider"
c_URL_TUMBLEBUG="http://localhost:1323/tumblebug"
c_URL_LADYBUG_NS="http://localhost:8080/ladybug/ns/${c_NS}"
c_CT="Content-Type: application/json"
c_AUTH="Authorization: Basic $(echo -n default:default | base64)"

# ------------------------------------------------------------------------------
if [ "$1" != "" ]; then CSP_1="$1"; fi
if [ "$2" != "" ]; then R_1="$2"; fi
if [ "$3" != "" ]; then CSP_2="$3"; fi
if [ "$4" != "" ]; then R_2="$4"; fi
if [ "$5" != "" ]; then CSP_3="$5"; fi
if [ "$6" != "" ]; then R_3="$6"; fi
if [ "${CSP_1}" == "" ]; then echo "Variable 'CSP #1' empty"; exit 0; fi
if [ "${CSP_2}" == "" ]; then echo "Variable 'CSP #2' empty"; exit 0; fi
if [ "${CSP_3}" == "" ]; then echo "Variable 'CSP #3' empty"; exit 0; fi
if [ "${R_1}" == "" ]; then echo "Variable 'R #1' empty"; exit 0; fi
if [ "${R_2}" == "" ]; then echo "Variable 'R #2' empty"; exit 0; fi
if [ "${R_3}" == "" ]; then echo "Variable 'R #3' empty"; exit 0; fi


if [ "${CSP_1}" == "aws" ];   then SPEC_1="t2.medium"; fi			#t2.large
if [ "${CSP_1}" == "gcp" ];   then SPEC_1="e2-highcpu-4"; fi 		#e2-standard-4
if [ "${CSP_1}" == "azure" ]; then SPEC_1="Standard_B2s"; fi

if [ "${CSP_2}" == "aws" ];   then SPEC_2="t2.medium"; fi			#t2.large
if [ "${CSP_2}" == "gcp" ];   then SPEC_2="e2-highcpu-4"; fi 		#e2-standard-4
if [ "${CSP_2}" == "azure" ]; then SPEC_2="Standard_B2s"; fi

if [ "${CSP_3}" == "aws" ];   then SPEC_3="t2.medium"; fi			#t2.large
if [ "${CSP_3}" == "gcp" ];   then SPEC_3="e2-highcpu-4"; fi 		#e2-standard-4
if [ "${CSP_3}" == "azure" ]; then SPEC_3="Standard_B2s"; fi


NM_CLUSTER="cb-${CSP_1}-${R_1}"
NM_CONFIG_1="config-${CSP_1}-${R_1}"
NM_CONFIG_2="config-${CSP_2}-${R_2}"
NM_CONFIG_3="config-${CSP_3}-${R_3}"


# ------------------------------------------------------------------------------
# 클러스터 생성
(
curl -sX POST -H "${c_CT}" ${c_URL_LADYBUG_NS}/clusters -d @- <<EOF
{
   "name": "${NM_CLUSTER}",
   "controlPlane": [
      { "connection": "${NM_CONFIG_1}", "count": 1, "spec": "${SPEC_1}" }
   ],
   "worker": [
      { "connection": "${NM_CONFIG_2}", "count": 1, "spec": "${SPEC_2}" },
      { "connection": "${NM_CONFIG_3}", "count": 1, "spec": "${SPEC_3}" }
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

# ------------------------------------------------------------------------------
# ssk key, kubeconfig 저장
./save-ssh-kubeconfig.sh "${CSP_1}" "${R_1}"

