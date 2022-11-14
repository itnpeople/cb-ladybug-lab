#!/bin/bash

for arg in "$@"
do
    KEY=$(echo $arg | cut -f1 -d=)
    VALUE=$(echo $arg | cut -f2 -d=)   

    case "$KEY" in
            hosts)      HOSTS=(${VALUE}) ;;
            ips)	    IPS=(${VALUE}) ;;
    esac    
done

echo "---------------------------------------------------------------------"
echo "haproxy"
echo "  - hosts : ${HOSTS[@]} (len=${#HOSTS[@]})"
echo "  - ip addresses : ${IPS[@]}  (len=${#IPS[@]})"
echo "---------------------------------------------------------------------"

if [ ${#HOSTS[@]} == 0 ] || [ ${#HOSTS[@]} != ${#IPS[@]} ]; then 
	echo "[ERROR] hosts.length != ips.length "
	exit 1
fi


SERVERS=""
for i in "${!HOSTS[@]}"; do
SERVERS+="  server  ${HOSTS[$i]}  ${IPS[$i]}:6443  check
"
done

sudo add-apt-repository -y ppa:vbernat/haproxy-1.7
sudo apt update
sudo apt install -y haproxy

sudo bash -c "cat << EOF > /etc/haproxy/haproxy.cfg
global
  log 127.0.0.1 local0
  maxconn 2000
  uid 0
  gid 0
  daemon
defaults
  log global
  mode tcp
  option dontlognull
  timeout connect 5000ms
  timeout client 50000ms
  timeout server 50000ms
frontend apiserver
  bind :9998
  default_backend apiserver
backend apiserver
  balance roundrobin
${SERVERS}
EOF"

# haproxy 재시작
sudo systemctl restart haproxy
