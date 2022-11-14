#!/bin/bash

# set default
ENDPOINT="$(dig +short myip.opendns.com @resolver1.opendns.com)"
SSHOPTS="-o StrictHostKeyChecking=no"
LB="haproxy"
CP_ENDPOINT=""
POD_CIDR="10.244.0.0/16"
SERVICE_CIDR="10.96.0.0/12"
DNS_DOMAIN="cluster.local"
ETCD="local"
ETCD_ENDPOINTS=""
IPS=()

# set variables
for arg in "$@"
do
    KEY=$(echo $arg | cut -f1 -d=)
    VALUE=$(echo $arg | cut -f2 -d=)   

    case "$KEY" in
            endpoint)      ENDPOINT=${VALUE} ;;
            lb)            LB=${VALUE} ;;
            podcidr)       POD_CIDR=${VALUE} ;;
            servicecidr)   SERVICE_CIDR=${VALUE} ;;
            domain)        DNS_DOMAIN=${VALUE} ;;
            etcd)          ETCD=(${VALUE}) ;;
            ips)           IPS=(${VALUE}) ;;
            *)   
    esac    
done

if [ "${ETCD}" == "external" ] ; then 
if [ ${#IPS[@]} == 0 ] ; then 
	echo "[ERROR] ip addresses is 0"
	exit 1
fi
for i in "${!IPS[@]}"; do
ETCD_ENDPOINTS+="
      - https://${IPS[$i]}:2379"
done
fi

if [ "${LB}" == "nlb" ] ; then 
	CP_ENDPOINT="${ENDPOINT}:6443"
else
	if [ "${LB}" == "haproxy" ] ; then 
		CP_ENDPOINT="${ENDPOINT}:9998"
	else
		echo "[ERROR] not supported lb type ${LB}"
		exit 1
	fi
fi

echo "---------------------------------------------------------------------"
echo "kubeadm init"
echo "  - endpoint : ${ENDPOINT}"
echo "  - loadbalancer : ${LB}"
echo "  - pod cidr : ${POD_CIDR}"
echo "  - service cidr : ${SERVICE_CIDR}"
echo "  - dns domain : ${DNS_DOMAIN}"
echo "  - control plane end-point : ${CP_ENDPOINT}"
if [ "${ETCD}" == "external" ] ; then 
	echo "	- etcd : ${ETCD}"
	echo "	- ip addresses : ${IPS}"
	echo "	- etcd end-points : ${ETCD_ENDPOINTS}"
fi
echo "---------------------------------------------------------------------"

CERT_KEY="$(kubeadm certs certificate-key)"
TOKEN="$(kubeadm token generate)"

if [ "${ETCD}" == "external" ] ; then 

# external etcd kubeadm-config 정의
cat << EOF > kubeadm-config.yaml
apiVersion: kubeadm.k8s.io/v1beta3
kind: InitConfiguration
bootstrapTokens:
- token: "$(kubeadm token generate)"
  description: "Proxy for managing TTL for the kubeadm-certs secret"
  ttl: "1h"
- token: "${TOKEN}"
  description: "kubeadm bootstrap token"
  ttl: "24h"
  usages:
  - authentication
  - signing
  groups:
  - system:bootstrappers:kubeadm:default-node-token
certificateKey: "${CERT_KEY}"
---
apiVersion: kubeadm.k8s.io/v1beta3
kind: ClusterConfiguration
imageRepository: k8s.gcr.io
controlPlaneEndpoint: ${CP_ENDPOINT}
dns:
  type: CoreDNS
apiServer:
  extraArgs:
    advertise-address: ${ENDPOINT}
    authorization-mode: Node,RBAC
etcd:
  external:
    endpoints:${ETCD_ENDPOINTS}
    caFile: /etc/kubernetes/pki/etcd/ca.crt
    certFile: /etc/kubernetes/pki/apiserver-etcd-client.crt
    keyFile: /etc/kubernetes/pki/apiserver-etcd-client.key
networking:
  dnsDomain: ${DNS_DOMAIN}
  podSubnet: ${POD_CIDR}
  serviceSubnet: ${SERVICE_CIDR}
controllerManager: {}
scheduler: {}
EOF

else

# local etcd kubeadm-config 정의
cat << EOF > kubeadm-config.yaml
apiVersion: kubeadm.k8s.io/v1beta3
kind: InitConfiguration
bootstrapTokens:
- token: "$(kubeadm token generate)"
  description: "Proxy for managing TTL for the kubeadm-certs secret"
  ttl: "1h"
- token: "${TOKEN}"
  description: "kubeadm bootstrap token"
  ttl: "24h"
  usages:
  - authentication
  - signing
  groups:
  - system:bootstrappers:kubeadm:default-node-token
certificateKey: "${CERT_KEY}"
---
apiVersion: kubeadm.k8s.io/v1beta2
kind: ClusterConfiguration
imageRepository: k8s.gcr.io
controlPlaneEndpoint: ${CP_ENDPOINT}
dns:
  type: CoreDNS
apiServer:
  extraArgs:
    advertise-address: ${ENDPOINT}
    authorization-mode: Node,RBAC
etcd:
  local:
    dataDir: /var/lib/etcd
networking:
  dnsDomain: ${DNS_DOMAIN}
  podSubnet: ${POD_CIDR}
  serviceSubnet: ${SERVICE_CIDR}
controllerManager: {}
scheduler: {}
EOF

fi

sudo kubeadm init --v=5 --upload-certs  --config kubeadm-config.yaml

# kubeconfig
find $HOME/.kube -name config -type f -delete
mkdir -p $HOME/.kube 
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config 
sudo chown $(id -u):$(id -g) $HOME/.kube/config 

# join 
HASH="$(openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //')"
for i in "${!IPS[@]}"; do
	if [ $i != 0 ]; then
		ssh ${SSHOPTS} ${USER}@${IPS[$i]} "sudo kubeadm join ${CP_ENDPOINT} --control-plane --token ${TOKEN} --discovery-token-ca-cert-hash sha256:${HASH} --certificate-key ${CERT_KEY}"
	fi
done
