#!/bin/bash
K8S_VERSION="1.23.12-00"	# curl https://packages.cloud.google.com/apt/dists/kubernetes-xenial/main/binary-amd64/Packages

sudo swapoff -a && sed -i '/swap/s/^/#/' /etc/fstab
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
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common gnupg2

# apg-get add repoisities
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add
sudo apt-add-repository "deb http://apt.kubernetes.io/ kubernetes-xenial main"
sudo add-apt-repository -y ppa:wireguard/wireguard
sudo add-apt-repository -y ppa:vbernat/haproxy-1.7
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
sudo apt-get install -y kubeadm=${K8S_VERSION} kubelet=${K8S_VERSION} kubectl=${K8S_VERSION}
sudo apt-mark hold kubeadm kubelet kubectl
sudo apt-get -y install nfs-common cifs-utils

sudo apt-get install -y wireguard
sudo apt install -y haproxy
