#!/bin/bash

# default values
VERSION="1.23.13"
HOSTNAME="$(hostname)"
ETCD="local"

# set variables
for arg in "$@"
do
    KEY=$(echo $arg | cut -f1 -d=)
    VALUE=$(echo $arg | cut -f2 -d=)   

    case "$KEY" in
            version)    VERSION=${VALUE} ;;
            hostname)   HOSTNAME=${VALUE} ;;
            etcd)      	ETCD=${VALUE} ;;
            *)   
    esac    
done

echo "---------------------------------------------------------------------"
echo "Bootstrap"
echo "  - version : $VERSION"
echo "  - hostname: $HOSTNAME"
echo "  - etcd: $ETCD"
echo "---------------------------------------------------------------------"

# hostname
sudo hostnamectl set-hostname ${HOSTNAME}

sudo swapoff -a && sudo sed -i '/swap/s/^/#/' /etc/fstab
# br_netfilter
sudo cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
br_netfilter
EOF

sudo cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sudo sysctl --system

#  default packages
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add
sudo apt-add-repository "deb http://apt.kubernetes.io/ kubernetes-xenial main"

sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common gnupg2
sudo apt-get update

# container runtime
sudo apt-get install -y containerd.io=1.2.13-2
cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF
sudo sysctl --system

sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sudo systemctl restart containerd

# kubeadm , kubelet, kubectl
sudo apt-get install -y kubeadm=${VERSION}-00 kubelet=${VERSION}-00 kubectl=${VERSION}-00
sudo apt-mark hold kubeadm kubelet kubectl
sudo apt-get -y install nfs-common cifs-utils


# download etcd
if [ "${ETCD}" == "external" ]; then 
	ETCD_VER="v3.4.22"
	curl -L https://storage.googleapis.com/etcd/${ETCD_VER}/etcd-${ETCD_VER}-linux-amd64.tar.gz -o etcd-${ETCD_VER}-linux-amd64.tar.gz
	tar xzvf etcd-${ETCD_VER}-linux-amd64.tar.gz
	sudo mv etcd-${ETCD_VER}-linux-amd64/etcd* /usr/local/bin/
	rm -f etcd-${ETCD_VER}-linux-amd64.tar.gz
fi
