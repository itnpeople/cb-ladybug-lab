#!/bin/bash
# ------------------------------------------------------------------------------
source ./env.sh


# ------------------------------------------------------------------------------
# print info.
echo ""
echo "[INFO]"
echo "- Namespace                  is '${c_NS}'"
echo "- Cluster name               is '${c_CLUSTER}'"
echo "- Connection Ifno.           is '${c_CONFIG}'"
echo "- Spec                       is '${c_SPEC}'"


# ------------------------------------------------------------------------------
# 클러스터 생성
(
curl -sX POST -H "${c_CT}" ${c_URL_MCKS_NS}/clusters -d @- <<EOF
{
   "name": "${c_CLUSTER}",
   "label": "lab.",
   "description": "create a cluster test",
   "controlPlane": [
      { "connection": "${c_CONFIG}", "count": 1, "spec": "${c_SPEC}" }
   ],
   "worker": [
      { "connection": "${c_CONFIG}", "count": 2, "spec": "${c_SPEC}" }
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
./save-ssh-kubeconfig.sh
