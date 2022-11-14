# External Etcd Topology on Control-Plane nodes
> cartifcate 파일 생성시 kubeadm 을 활용 etcd 설치 호스트에 kubeadm 설치되어 있어야함

## 환경

* Control-plane 설치 호스트 3개
* external etcd 동일 호스트에 설치
* haproxy 로 lb 처리

```
external-etcd-1 10.146.0.16
external-etcd-2 10.146.0.17
external-etcd-3 10.146.0.18
```


## 설치 절차

### bootstrap
> 모든 Control-Plane 설치 호스트에서 실행

* `bootstrap-1.23.sh`
  * version : "1.23.13"(default), version="1.23.10"
  * hostname : 호스트(노드명)
  * etcd : "local", "external"

* 예
```
$ ./bootstrap-1.23.sh etcd=external
```

### 2. SSH passwordless
> 리더 호스트에서

* 동일한 public-key(authorized_keys) 를 공유하고 있다는 전제
* scp, ssh 사용 목적

```
$ echo '-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAABFwAAAAdzc2gtcn
NhAAAAAwEAAQAAAQEAy4X7Ery2F05HJg9HHXaklgxdaXaBL5J8wTz4XzQutnmn22c8I8pN
EoCc/LIio6QuCIxh46VM9OX4iNtz7g+nbAhDMFpo9xbPgaMfa6tEALxMX2Ko2VzWwPZy2j
hTTQN73atvfzgADAuXatC1perh4DH5Z8I/YuM537wurpznxVkaErFBUEaXJoYYBbpC57+U
YmPTHV1ujAlykYMwZXVnCw42OW/dyjFXA0oT3hsRhg8KBXxMF/64860qIxGTDTkBFkaLA6
nNSqq4cv7JLdK6HTVdlpVFsTifTrRVAq4vOCZiM0/KQ4EQnchr7v3AiuRcvZdEANu6phYP
7DAjONDcdwAAA8AptxULKbcVCwAAAAdzc2gtcnNhAAABAQDLhfsSvLYXTkcmD0cddqSWDF
1pdoEvknzBPPhfNC62eafbZzwjyk0SgJz8siKjpC4IjGHjpUz05fiI23PuD6dsCEMwWmj3
Fs+Box9rq0QAvExfYqjZXNbA9nLaOFNNA3vdq29/OAAMC5dq0LWl6uHgMflnwj9i4znfvC
6unOfFWRoSsUFQRpcmhhgFukLnv5RiY9MdXW6MCXKRgzBldWcLDjY5b93KMVcDShPeGxGG
DwoFfEwX/rjzrSojEZMNOQEWRosDqc1Kqrhy/skt0rodNV2WlUWxOJ9OtFUCri84JmIzT8
pDgRCdyGvu/cCK5Fy9l0QA27qmAAwEAAQAAAQEAxswcNWNF9L48A1aq0v9PgUk3EjyyGNd
9JKiG4rCZ7SAZYZx45L5jIz9H/JfGrmRDeiaNft43H/nw+4npOPy7hjVvdUwWgX6DEwwHh
9H+eAl7UzTre43T8U/rHRBKV7GTWMYxe00rKEeBPjlMdY2F48MxLdB1O0+sW1n6sUFt+sO
XTpUmo1HD/pljeZG4e1MN5EHn3Fg/sMCM40Nx3AAAGTP+uOopN9oQzAorysN3Ye/k7O+XS
Z51c1AktjbXDH/PPRJW2OjLDm7yFig6i1ra9Fn5VjHimKQaI5fQonP061aq0CfxjC5VkFq
L4H6v55orWfv8ifLTz7q0CUygCYJCQNj6SzZnDwHpwna4QAAAIBqyxGHGM40W5Md0KYnq6
3oNaaIvdF1ss72zohcMP2sJgkG4JdKxypWGYrwDKWdhKk969RNDolqSFPW7CfjwX+BTFtx
vmUAFYy5Tj0ijlKpO0SM8x+cyczriZFMy1enCI/czYihETdGGofLGQ1vec+TaCNSkAWISp
ISaDA2usMUbAAAAIEA8+P5p86dUfTLi3jcEC6b9NDxnaO99Y7wQzFdYs9fcNKf19ybai/D
ugkPmhSipoIb5tXxDc/N0Xnci2wjyqqUw28zK+JOx+DQDh8SFGiqxuGiud6LpFPsZxzkda
jHUck1JxXZeCs5VHcpkUmWgs+caE5F3NpDFT5rjYlk/k8ZtScAAACBANWg6OItkWQhAns8
gDkInaK/t02eXiZYjYBSfTsoxsXXrcsQHg7SMJhhA1IaakF/K9C5juJ71C5BrRUB5ELN5x
yzfc3kMc/b6aiFBEcF/FlddVp/W2L/T1ljNd7V25X6ehkKaf2KFksLhRknwX3jZk4cyH6J
ftIKTAEbnZt5D1AxAAAABWVzY2hvAQIDBAU=
-----END OPENSSH PRIVATE KEY-----'  > ~/.ssh/id_rsa

$ chmod 600 ~/.ssh/id_rsa
```

### Kubernetes control-plane provisining
> 리더 호스트에서

* `install-haproxy.sh`
  * hosts : control-plane 호스트명 (spacebar로 구분)
  * ips : control-plane IP (spacebar로 구분)

* `install-external-etcd.sh`
  * hosts : etcd cluster 호스트명 (spacebar로 구분)
  * ips : etcd cluster  IP (spacebar로 구분)

* `kubeadm-init.sh`
  * endpoint
  * lb : haproxy, nlb
  * etcd "local", "external"
  * podcidr "10.244.0.0/16"
  * servicecidr "10.96.0.0/12"
  * domain "10.96.0.0/12"
  * ips : control-plane IP (spacebar로 구분)

* 예

```
$ HOST="external-etcd-1 external-etcd-2 external-etcd-3"
$ IPS="10.146.0.16 10.146.0.17 10.146.0.18"
$ ETCD_HOST="external-etcd-1 external-etcd-2 external-etcd-3"
$ ETCD_IPS="10.146.0.16 10.146.0.17 10.146.0.18"

$ ./install-haproxy.sh hosts="${HOST}" ips="${IPS}"
$ ./install-external-etcd.sh hosts="${ETCD_HOST}" ips="${ETCD_IPS}"
$ ./kubeadm-init.sh lb=haproxy etcd=external ips="${IPS}"
```


## clean-up

```
# on all members

$ sudo kubeadm reset
$ sudo systemctl stop etcd
$ sudo rm ${HOME}/etcd-external-etcd-2.service /etc/systemd/system/etcd.service /lib/systemd/system/mcks-bootstrap /lib/systemd/system/mcks-bootstrap.service
$ sudo systemctl daemon-reload

# 리터노드에서만
$ rm ~/.ssh/id_rsa
$ sudo systemctl stop haproxy
$ sudo /etc/haproxy/haproxy.cfg
```

## 참고

* https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/setup-ha-etcd-with-kubeadm/
* https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/high-availability/#external-etcd-nodes
* https://kubernetes.io/docs/reference/config-api/kubeadm-config.v1beta3/
* https://kubernetes.io/ko/docs/tasks/administer-cluster/certificates/
