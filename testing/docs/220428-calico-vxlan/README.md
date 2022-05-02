# Calico(vxlan) Cross-CSP 설치 검토
> Using `cbctl` (https://github.com/itnpeople/cbctl)

## 개요
* https://github.com/cloud-barista/cb-mcks/pull/133
* 해당 PR에서 Calico 설치 문제 없으나 Cross-CSP 환경에서 노드간 통신이 안되는 현상이 발견되어 수동 설치 테스트를 진행
* 1단계 설치 테스트, 2단계 세부 검토 진행


### 검토 환경

* Calico 테스트 버전 : 3.22.0, 3.22.2
* VXLAN 라우팅 적용, BGP 라우팅 방식은 고려 안함(Azure IP-in-IP 지원안함)
* VXLAN calico/node 설정 (DaemonSet 환경변수)
  * IP : IP 셋팅 ("autodetect": 자동감지, "none" : disable, "" : 이전 설정 IP 사용)
  * CALICO_NETWORKING_BACKEND : 백엔드 아키텍처 ("vxlan" / "bird")
  * CALICO_IPV4POOL_IPIP : IP-in-IP 모드 ("Never", "CrossSubnet", "Always")
  * CALICO_IPV4POOL_VXLAN : vxlan 모드 ("Never", "CrossSubnet", "Always")
  * CALICO_IPV4POOL_CIDR : Pod Subnet Cidr "10.244.0.0/16"
  * CALICO_IPV4POOL_BLOCK_SIZE : Pod Subnet blocksize
* 노드 어노테이션 "projectcalico.org/IPv4Address" 에 해당 노드의 공인IP 값 지정

* 멀티 CSP : AWS + GCP (tokyo 리전)
```
NAME        STATUS     ROLES    AGE    VERSION   INTERNAL-IP      EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION   CONTAINER-RUNTIME
c-1-h43jk   NotReady   master   112m   v1.18.9   52.199.85.152    <none>        Ubuntu 18.04.5 LTS   5.3.0-1035-aws   docker://19.3.11
w-1-36384   NotReady   <none>   112m   v1.18.9   34.146.125.113   <none>        Ubuntu 18.04.5 LTS   5.4.0-1028-gcp   docker://19.3.11
```

## 1단계 설치 테스트

* `kube-system` 네임스페이스에 calico/node, calico-controller, coredns 정상 실행 여부 확인
* 만일 정상 설치되었다면 노드 터미널 접속하여 다른 노드의 Pod-IP  `ping` 여부 확인

### 준비작업

* Create a Cluster 예 (AWS + GCP = 1: 1)

```
$ cbctl cluster create -f - <<EOF
name: cb-cluster
label: lab.
description: create a cluster test
controlPlane:
  - connection: config-aws-tokyo
    count: 1
    spec: t2.medium
worker:
  - connection: config-gcp-tokyo
    count: 1
    spec: e2-highcpu-4
config:
  kubernetes:
    networkCni: calico
    podCidr: 10.244.0.0/16
    serviceCidr: 10.96.0.0/12
    serviceDnsDomain: cluster.local
EOF
```

* Kubeconfig 업데이트

```
$ cbctl cluster update-kubeconfig cb-cluster
```

* 노드 이름, IP 조회
```
$ MASTER="$(kubectl get node -o custom-columns=:metadata.name --no-headers | awk 'NR==1 { print;}')"
$ WORKER="$(kubectl get node -o custom-columns=:metadata.name --no-headers | awk 'NR==2 { print;}')"
$ MASTER_IP="$(kubectl get node -o custom-columns=:status.addresses[0].address --no-headers | awk 'NR==1 { print;}')"
$ WORKER_IP="$(kubectl get node -o custom-columns=:status.addresses[0].address --no-headers | awk 'NR==2 { print;}')"
$ echo "MASTER=\"${MASTER}\"; WORKER=\"${WORKER}\"; MASTER_IP=\"${MASTER_IP}\"; WORKER_IP=\"${WORKER_IP}\""
```

* 노드 SSH 접속

```
# Control-Plane
$ cbctl node get-key ${MASTER}  --cluster cb-cluster  > ssh/${MASTER}.pem
$ chmod 400 ssh/${MASTER}.pem
$ ssh -i ssh/${MASTER}.pem cb-user@${MASTER_IP}

# Wokrer Node
$ cbctl node get-key ${WORKER} --cluster cb-cluster  > ssh/${WORKER}.pem
$ chmod 400 ssh/${WORKER}.pem
$ ssh -i ssh/${WORKER}.pem cb-user@${WORKER_IP}
```


### Calico 설치 (4종)

* BGP(ipip) + ip "autodetect" (private-ip)
  * IP : "autodetect"
  * CALICO_NETWORKING_BACKEND : "bird"
  * CALICO_IPV4POOL_IPIP : "Always"
  * CALICO_IPV4POOL_VXLAN : "Never"
  * CALICO_IPV4POOL_CIDR : "10.244.0.0/16"

```
$ kubectl apply -f yaml/1.calico-commons.yaml
$ kubectl apply -f yaml/2.bgp-autodetect.yaml
```

* BGP(ipip) + public-ip
  * IP : ""
  * CALICO_NETWORKING_BACKEND : "bird"
  * CALICO_IPV4POOL_IPIP : "Always"
  * CALICO_IPV4POOL_VXLAN : "Never"
  * CALICO_IPV4POOL_CIDR : "10.244.0.0/16"

```
$ kubectl annotate node ${MASTER} projectcalico.org/IPv4Address=${MASTER_IP} --overwrite
$ kubectl annotate node ${WORKER} projectcalico.org/IPv4Address=${WORKER_IP} --overwrite
$ kubectl apply -f yaml/1.calico-commons.yaml
$ kubectl apply -f yaml/2.bgp.yaml
```


* VXLAN + ip="autodetect" (private-ip)
  * IP : "autodetect"
  * CALICO_NETWORKING_BACKEND : "vxlan"
  * CALICO_IPV4POOL_IPIP : "Never"
  * CALICO_IPV4POOL_VXLAN : "Always"
  * CALICO_IPV4POOL_CIDR : "10.244.0.0/16"
  * CALICO_IPV4POOL_BLOCK_SIZE : "24"
```
$ kubectl apply -f yaml/1.calico-commons.yaml
$ kubectl apply -f yaml/3.vxlan-autodetect.yaml
```


* VXLAN + public-ip 
  * IP : ""
  * CALICO_NETWORKING_BACKEND : "vxlan"
  * CALICO_IPV4POOL_IPIP : "Never"
  * CALICO_IPV4POOL_VXLAN : "Always"
  * CALICO_IPV4POOL_CIDR : "10.244.0.0/16"
  * CALICO_IPV4POOL_BLOCK_SIZE : "24"
```
$ kubectl annotate node ${MASTER} projectcalico.org/IPv4Address=${MASTER_IP} --overwrite
$ kubectl annotate node ${WORKER} projectcalico.org/IPv4Address=${WORKER_IP} --overwrite
$ kubectl apply -f yaml/1.calico-commons.yaml
$ kubectl apply -f yaml/3.vxlan.yaml
```

### Calico 설치 및 Ping 테스트 결과

| CSP        |라우팅 |IPv4Address |설치 |`ping`|비고                                                 |
|---         |---    |---         |:---:|:---: |---                                                  |
| Cross-CSP  | VXLAN | private-ip | O   | X    |                                                     |
| Cross-CSP  | VXLAN | public-ip  | O   | X    |                                                     |
| Cross-CSP  | BGP   | private-ip | X   | .    | calico/node 컨테이너가 시작되지 못함 ( 0/1 Running) |
| Cross-CSP  | BGP   | public-ip  | X   | .    | (상동)                                              |
| Single-CSP | VXLAN | private-ip | O   | O    |                                                     |
| Single-CSP | VXLAN | public-ip  | O   | X    |                                                     |
| Single-CSP | BGP   | private-ip | O   | O    |                                                     |
| Single-CSP | BGP   | public-ip  | X   | .    | calico/node 컨테이너가 시작되지 못함 ( 0/1 Running) |

* vxlan, bgp 모두 Single CSP + private-ip 인 경우만 설치 및 Pod 라우팅 가능.
* `projectcalico.org/IPv4Address` 어노테이션에 Public-IP를 지정한 경우
  * bgp 인 경우  Single/Cross CSP 모두 설치 불가.
  * vxlan 인 경우 Cross/Single CSP 모두 설치 가능하지만 `bird` 프로세스가 liveness 에서 제외 되었기 때문일 수 있음.


## 2단계  세부 검토

* Cross-CSP + VXLAN + public-ip 설치 후 세부 설정 검토 작업 수행

### 주요 vxlan 설정 조회 명령 

```
$ route                               # routing table 출력
$ ip -d link show vxlan.calico        # iface "vxlan.calico" 세부 출력
$ ip neigh show | grep vxlan.calico   # APR(Address Resolution Protocol), NDP(Neighbor Discover Protocol) 출력
$ bridge fdb | grep vxlan.calico      # FDB(forwarding database) 출력
```

### 설치 현황 -> 노드 간 통신 불가.

* `route`
  * Pod Cidr 각각 10.244.122.0/24, 10.244.124.0/24 로 지정됨
  * Tunneling iface "vxlan.calico"
  * iface "cali..." 는 Pod IP

```
# 노드 #1 (AWS, 54.64.9.64/192.168.10.28)
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
default         _gateway        0.0.0.0         UG    100    0        0 eth0
10.244.122.0    0.0.0.0         255.255.255.0   U     0      0        0 *
10.244.122.1    0.0.0.0         255.255.255.255 UH    0      0        0 calia9693f7b251
10.244.124.0    10.244.124.0    255.255.255.0   UG    0      0        0 vxlan.calico
172.17.0.0      0.0.0.0         255.255.0.0     U     0      0        0 docker0
192.168.10.0    0.0.0.0         255.255.255.0   U     0      0        0 eth0
_gateway        0.0.0.0         255.255.255.255 UH    100    0        0 eth0

# 노드 #2 (GCP, 35.189.140.156/192.168.29.28)
Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
default         _gateway        0.0.0.0         UG    100    0        0 ens4
10.244.122.0    10.244.122.0    255.255.255.0   UG    0      0        0 vxlan.calico
10.244.124.0    0.0.0.0         255.255.255.0   U     0      0        0 *
10.244.124.1    0.0.0.0         255.255.255.255 UH    0      0        0 cali140ea26fc35
10.244.124.2    0.0.0.0         255.255.255.255 UH    0      0        0 cali4ab1529590f
172.17.0.0      0.0.0.0         255.255.0.0     U     0      0        0 docker0
_gateway        0.0.0.0         255.255.255.255 UH    100    0        0 ens4
```

* 다른 노드의 Pod IP로 ping 확인 -> Pending

```
# 노드 #1 (AWS, 54.64.9.64/192.168.10.28)
ping 10.244.124.1

# 노드 #2 (GCP, 35.189.140.156/192.168.29.28)
ping 10.244.122.1
```

### 네트워크 및 라우팅 체크

* `ip -d link show vxlan.calico`
  * vxlan.calico iface 는 vxlan 공인IP로 지정됨 (projectcalico.org/IPv4Address 어노테이션)

```
# 노드 #1 (AWS, 54.64.9.64/192.168.10.28)
8: vxlan.calico: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 8951 qdisc noqueue state UNKNOWN mode DEFAULT group default
    link/ether 66:f6:10:93:e0:06 brd ff:ff:ff:ff:ff:ff promiscuity 0
    vxlan id 4096 local 54.64.9.64 dev eth0 srcport 0 0 dstport 4789 nolearning ttl inherit ageing 300 udpcsum noudp6zerocsumtx noudp6zerocsumrx addrgenmode eui64 numtxqueues 1 numrxqueues 1 gso_max_size 65536 gso_max_segs 65535

# 노드 #2 (GCP, 35.189.140.156/192.168.29.28)
9: vxlan.calico: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1410 qdisc noqueue state UNKNOWN mode DEFAULT group default
    link/ether 66:09:ac:35:3b:2d brd ff:ff:ff:ff:ff:ff promiscuity 0
    vxlan id 4096 local 35.189.140.156 dev ens4 srcport 0 0 dstport 4789 nolearning ttl inherit ageing 300 udpcsum noudp6zerocsumtx noudp6zerocsumrx addrgenmode eui64 numtxqueues 1 numrxqueues 1 gso_max_size 65536 gso_max_segs 65535
```

* `ip neigh show | grep vxlan.calico` + `bridge fdb | grep vxlan.calico`
  * APR, FDB 에서 MAC 주소 동일 여부 확인
  * FDB destionation 공인IP 지정

```
# 노드 #1 (AWS, 54.64.9.64/192.168.10.28)
10.244.124.0 dev vxlan.calico lladdr 66:09:ac:35:3b:2d PERMANENT
66:09:ac:35:3b:2d dev vxlan.calico dst 35.189.140.156 self permanent

# 노드 #2 (GCP, 35.189.140.156/192.168.29.28)
10.244.122.0 dev vxlan.calico lladdr 66:f6:10:93:e0:06 PERMANENT
66:f6:10:93:e0:06 dev vxlan.calico dst 54.64.9.64 self permanent
```

* `ip link show`
  * 노드 #1에서 노드 #2의 FDB 의 MAC "66:f6:10:93:e0:06" 여부 확인
  * 노드 #2에서 노드 #1의 FDB 의 MAC "66:09:ac:35:3b:2d" 여부 확인
```
# 노드 #1 (AWS, 54.64.9.64/192.168.10.28)
8: vxlan.calico: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 8951 qdisc noqueue state UNKNOWN mode DEFAULT group default
    link/ether 66:f6:10:93:e0:06 brd ff:ff:ff:ff:ff:ff

# 노드 #2 (GCP, 35.189.140.156/192.168.29.28)
9: vxlan.calico: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1410 qdisc noqueue state UNKNOWN mode DEFAULT group default
    link/ether 66:09:ac:35:3b:2d brd ff:ff:ff:ff:ff:ff
```

### flannel vxlan 설정과 비교

* Calico(vxlan) 의 경우 vxlan iface "vxlan.calico" vxlan local 이 Pulbic-IP로 지정되어 있으나 flannel에서 vxlan iface "flannel.1" 는 Private-IP로 지정되어 있음 확인

## 결론 (권장사항)

* MCKS는 각 노드의 Internal-IP를 Public-IP로 지정하여 운영되는 형태.
* flannel(canal)은 iface(`flannel.1`) 을 통해 Cross-CSP 노드간 공인IP(`flannel.alpha.coreos.com/public-ip`)로 vxlan 터널링하는 간단한 L2기반 구조.
* 하지만 Clico(vxlan)는 L3기반 내부 Linux 라우팅 메커니즘을 가지고 있어서 Cross-CSP 에서 운영 불가한 것으로 보임.
* Calico에서 vxlan 라우팅은 3.7 이상부터 지원되는것으로 명시되어 있으나 CrossSubnet 노드간 통신이 가능한 환경에서만 적용 가능한 것으로 판단.
* MCKS(Public-IP 운영 구조) 에서는 Network-CNI로 Calico 를 활용하고자 할 때 Canal 사용 권장.

## 기타 참조

* 주요 참조 사이트
  * [Calico Reference Architecture](https://tanzu.vmware.com/developer/guides/container-networking-calico-refarch/)
  * [[번역]Calico 라우팅 모드](https://coffeewhale.com/calico-mode)
  * [Configure the Calico CNI plugins](https://projectcalico.docs.tigera.io/reference/cni-plugin/configuration)
  * [Kubernetes 네트워크 이해하기](https://speakerdeck.com/devinjeon/kubernetes-neteuweokeu-ihaehagi-1-keonteineo-neteuweokeubuteo-cniggaji?slide=53)
  * [Calico의 Overlay 네트워킹](https://eddie.ee/186)
  * [Flannel vs Calico : L2 vs L3 기반 네트워킹의 대결](https://medium.com/@jain.sm/flannel-vs-calico-a-battle-of-l2-vs-l3-based-networking-5a30cd0a3ebd)
  * [Cluster network - flannel and calico](https://programming.vip/docs/042-cluster-network-flannel-and-calico.html)

* calicoctl 설치 (각 노드에서)

```
$ sudo curl -L  https://github.com/projectcalico/calicoctl/releases/download/v3.16.3/calicoctl -o /usr/local/bin/calicoctl
$ sudo chmod +x /usr/local/bin/calicoctl
$ sudo calicoctl node status
```

* IP_AUTODETECTION 방법 지정
```
$ kubectl set env daemonset/calico-node -n kube-system IP_AUTODETECTION_METHOD=kubernetes-internal-ip
```


* 어노테이션
```
$ kubectl annotate node ${MASTER} projectcalico.org/IPv4Address=192.168.10.76 --overwrite
$ kubectl annotate node ${WORKER} projectcalico.org/IPv4Address=192.168.29.27 --overwrite


$ kubectl annotate node ${MASTER} projectcalico.org/IPv4Address-
$ kubectl annotate node ${MASTER} projectcalico.org/IPv4IPIPTunnelAddr-

$ kubectl annotate node ${WORKER} projectcalico.org/IPv4Address-
$ kubectl annotate node ${WORKER} projectcalico.org/IPv4IPIPTunnelAddr-

```

* tcpdump

```
$ tcpdump -i eth0 src 10.244.191.1 and port 80 and dst 10.244.61.65
$ tcpdump -i eth0 src 10.244.191.1 and dst 10.244.61.65
```

