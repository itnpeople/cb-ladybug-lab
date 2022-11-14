#!/bin/bash

# default value
SSHOPTS="-o StrictHostKeyChecking=no"
HOSTS=()
IPS=()

# set variables
for arg in "$@"
do
    KEY=$(echo $arg | cut -f1 -d=)
    VALUE=$(echo $arg | cut -f2 -d=)   

    case "$KEY" in
            hosts)    HOSTS=(${VALUE}) ;;
            ips)   	  IPS=(${VALUE}) ;;
            *) 
    esac    
done

if [ ${#HOSTS[@]} == 0 ] || [ ${#HOSTS[@]} != ${#IPS[@]} ]; then 
	echo "[ERROR] hosts.length != ips.length "
	exit 1
fi
CLUSTER=""
for i in "${!IPS[@]}"; do
CLUSTER+="${HOSTS[$i]}=https://${IPS[$i]}:2380,"
done
CLUSTER="${CLUSTER%\,}"

echo "---------------------------------------------------------------------"
echo "Install etcd"
echo "  - hosts : ${HOSTS[@]} (len=${#HOSTS[@]})"
echo "  - ip addresses : ${IPS[@]}  (len=${#IPS[@]})"
echo "  - cluster : ${CLUSTER}"
echo "---------------------------------------------------------------------"


# ------------------------------------------
# Generate the certificate authority
# 	This creates two files
# 	/etc/kubernetes/pki/etcd/ca.crt
# 	/etc/kubernetes/pki/etcd/ca.key
sudo find /etc/kubernetes/pki -type f -delete &> /dev/null
sudo kubeadm init phase certs etcd-ca

# ------------------------------------------
# Copy "etcd-ca" certificates 
sudo find ${HOME}/pki -delete &> /dev/null
sudo cp -R /etc/kubernetes/pki ${HOME}/
sudo chown -R $(id -u):$(id -g) pki

for i in "${!IPS[@]}"; do
	if [ $i != 0 ]; then
		ssh ${SSHOPTS} ${USER}@${IPS[$i]} 'sudo find ${HOME}/pki -delete &> /dev/null && sudo rm -rf /etc/kubernetes/pki/etcd/ && sudo find /etc/kubernetes/pki -type f -delete &> /dev/null'
		scp ${SSHOPTS} -r ${HOME}/pki ${USER}@${IPS[$i]}:
		ssh ${SSHOPTS} ${USER}@${IPS[$i]} 'sudo chown -R root:root pki && sudo cp -R pki /etc/kubernetes/'
	fi
done

for i in "${!IPS[@]}"; do
	if [ $i == 0 ]; then
		sudo kubeadm init phase certs etcd-server
		sudo kubeadm init phase certs etcd-peer
		sudo kubeadm init phase certs etcd-healthcheck-client
		sudo kubeadm init phase certs apiserver-etcd-client
	else
		ssh ${SSHOPTS} ${USER}@${IPS[$i]} 'sudo kubeadm init phase certs etcd-server'
		ssh ${SSHOPTS} ${USER}@${IPS[$i]} 'sudo kubeadm init phase certs etcd-peer'
		ssh ${SSHOPTS} ${USER}@${IPS[$i]} 'sudo kubeadm init phase certs etcd-healthcheck-client'
		ssh ${SSHOPTS} ${USER}@${IPS[$i]} 'sudo kubeadm init phase certs apiserver-etcd-client'
		ssh ${SSHOPTS} ${USER}@${IPS[$i]} 'sudo find /etc/kubernetes/pki/etcd -name ca.key -type f -delete'
	fi
done

# ----------------------------------------
# Create certificates for each member
# 	on HOST0
#	/etc/kubernetes/pki
#	├── apiserver-etcd-client.crt
#	├── apiserver-etcd-client.key
#	└── etcd
#	    ├── ca.crt
#	    ├── ca.key
#	    ├── healthcheck-client.crt
#	    ├── healthcheck-client.key
#	    ├── peer.crt
#	    ├── peer.key
#	    ├── server.crt
#	    └── server.key

# 	on HOST1, HOST2
#	/etc/kubernetes/pki
#	├── apiserver-etcd-client.crt
#	├── apiserver-etcd-client.key
#	└── etcd
#	    ├── ca.crt
#	    ├── healthcheck-client.crt
#	    ├── healthcheck-client.key
#	    ├── peer.crt
#	    ├── peer.key
#	    ├── server.crt
#	    └── server.key


# ----------------------------------------
# 6. Create etcd daemon service files for each members
for i in "${!HOSTS[@]}"; do

sudo find ${HOME} -name etcd-${HOSTS[$i]}.service -type f -delete
cat <<EOF > /${HOME}/etcd-${HOSTS[$i]}.service
[Unit]
Description=etcd

[Service]
Type=exec
ExecStart=/usr/local/bin/etcd \\
  --name=${HOSTS[$i]}  \\
  --data-dir=/var/lib/etcd \\
  --advertise-client-urls=https://${IPS[$i]}:2379 \\
  --initial-advertise-peer-urls=https://${IPS[$i]}:2380 \\
  --initial-cluster=certificate-1=https://${IPS[$i]}:2380 \\
  --listen-client-urls=https://127.0.0.1:2379,https://${IPS[$i]}:2379 \\
  --listen-metrics-urls=http://127.0.0.1:2381 \\
  --listen-peer-urls=https://${IPS[$i]}:2380 \\
  --cert-file=/etc/kubernetes/pki/etcd/server.crt \\
  --key-file=/etc/kubernetes/pki/etcd/server.key \\
  --peer-cert-file=/etc/kubernetes/pki/etcd/peer.crt \\
  --peer-key-file=/etc/kubernetes/pki/etcd/peer.key \\
  --peer-client-cert-auth=true \\
  --peer-trusted-ca-file=/etc/kubernetes/pki/etcd/ca.crt \\
  --trusted-ca-file=/etc/kubernetes/pki/etcd/ca.crt \\
  --client-cert-auth=true \\
  --experimental-initial-corrupt-check=true \\
  --experimental-watch-progress-notify-interval=5s \\
  --snapshot-count=10000 \\
  --initial-cluster-token=etcd-cluster \\
  --initial-cluster=${CLUSTER} \\
  --initial-cluster-state=new
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

	if [ $i == 0 ]; then
		sudo chown root.root ${HOME}/etcd-${HOSTS[0]}.service
		sudo cp ${HOME}/etcd-${HOSTS[0]}.service /etc/systemd/system/etcd.service
		sudo systemctl daemon-reload
		sudo systemctl enable --now etcd
		sudo systemctl restart etcd
	else
		ssh ${SSHOPTS} ${USER}@${IPS[$i]} "sudo find ${HOME} -name etcd-${HOSTS[$i]}.service -type f -delete"
		scp ${SSHOPTS} ${HOME}/etcd-${HOSTS[$i]}.service ${USER}@${IPS[$i]}:
		ssh ${SSHOPTS} ${USER}@${IPS[$i]} "sudo chown root.root ${HOME}/etcd-${HOSTS[$i]}.service"
		ssh ${SSHOPTS} ${USER}@${IPS[$i]} "sudo cp ${HOME}/etcd-${HOSTS[$i]}.service /etc/systemd/system/etcd.service"
		ssh ${SSHOPTS} ${USER}@${IPS[$i]} "sudo systemctl daemon-reload"
		ssh ${SSHOPTS} ${USER}@${IPS[$i]} "sudo systemctl enable --now etcd"
		ssh ${SSHOPTS} ${USER}@${IPS[$i]} "sudo systemctl restart etcd"
	fi
done
