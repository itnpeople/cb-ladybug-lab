#!/bin/bash
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


source ./env.sh "${CSP_1}" "${R_1}"
echo "$CSP_1 $c_CONFIG $c_SPEC"
c_CONFIG_1="${c_CONFIG}"
c_SPEC_1="${c_SPEC}"

source ./env.sh "${CSP_2}" "${R_2}"
echo "$CSP_2 $c_CONFIG $c_SPEC"
c_CONFIG_2="${c_CONFIG}"
c_SPEC_2="${c_SPEC}"

source ./env.sh "${CSP_3}" "${R_3}"
c_CONFIG_3="${c_CONFIG}"
c_SPEC_3="${c_SPEC}"


#c_CLUSTER="${R_1}"

# ------------------------------------------------------------------------------
# print info.
echo ""
echo "[INFO]"
echo "- Namespace                  is '${c_NS}'"
echo "- Cluster name               is '${c_CLUSTER}'"
echo "- Connection Ifno.           is '${c_CONFIG_1}', '${c_CONFIG_2}','${c_CONFIG_3}'"
echo "- Spec                       is '${c_SPEC_1}', '${c_SPEC_2}', '${c_SPEC_3}'"



# ------------------------------------------------------------------------------
# 클러스터 생성
(
curl -sX POST -H "${c_CT}" ${c_URL_MCKS_NS}/clusters -d @- <<EOF
{
   "name": "${c_CLUSTER}",
   "controlPlane": [
      { "connection": "${c_CONFIG_1}", "count": 1, "spec": "${c_SPEC_1}" }
   ],
   "worker": [
      { "connection": "${c_CONFIG_2}", "count": 1, "spec": "${c_SPEC_2}" },
      { "connection": "${c_CONFIG_3}", "count": 1, "spec": "${c_SPEC_3}" }
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

curl -sX GET -H "${c_CT}" ${c_URL_MCKS_NS}/clusters | jq > ./output/clusters.json

# ------------------------------------------------------------------------------
# ssk key, kubeconfig 저장
./save-ssh-kubeconfig.sh "${CSP_1}" "${R_1}"

