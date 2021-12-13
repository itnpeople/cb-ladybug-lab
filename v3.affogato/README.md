# CB-MCKS Lab.
* https://github.com/cloud-barista/cb-spider/wiki/How-to-get-CSP-Credentials


## Prerequisites

* jq

```
$ brew install jq
```


## 실행

```
$ ./startup.sh

# logs
$ docker logs cb-mcks -f
```

## 공통

* Set `CLUSTER` environment variable

```
$ export CLUSTER="my-cluster"
```


* CSP (aws, gcp, azure, tencent)
* Region (seoul, tokyo, singapore, usca, london)
* CSP별 credential 파일 정의

```
$ export CSP="aws";      export R="tokyo";      export FILE="${HOME}/.aws/credentials"
$ export CSP="gcp";      export R="usca";       export FILE="${HOME}/.ssh/google-credential-cloudbarista.json"
$ export CSP="azure";    export R="london";     export FILE="${HOME}/.azure/azure-credential-cloudbarista.json"
$ export CSP="tencent";  export R="singapore";  export FILE="${HOME}/.tccli/default.credential"
```


## Use Case #1 : Single-Cloud Provisioning


* Set `CLUSTER` environment variable

```
$ export CLUSTER="cb-cluster-1"
```

* create a connection info

```
$ ./init.sh "aws"     "tokyo"     "${HOME}/.aws/credentials"
$ ./init.sh "gcp"     "usca"      "${HOME}/.ssh/google-credential-cloudbarista.json"
$ ./init.sh "azure"   "london"    "${HOME}/.azure/azure-credential-cloudbarista.json"
$ ./init.sh "alibaba"  "tokyo"    "${HOME}/.ssh/alibaba_accesskey.csv"
$ ./init.sh "tencent" "singapore" "${HOME}/.tccli/default.credential"

$ source ${HOME}/.ssh/openstack-openrc.sh
$ ./init.sh "openstack"

# clean-up
# ./cleanup-init.sh "aws" "tokyo" 
```

* Create a cluster

```
$ ./create-cluster.sh "aws" "tokyo"

# if openstack
$ ./create-cluster.sh "openstack"
```

* Delete a cluster

```
$ ./delete-cluster.sh
```


## Use Case #2 : Double-Clouds Provisioning


* Set `CLUSTER` environment variable

```
$ export CLUSTER="cb-cluster-2"
```


* Create a connection info

```
$ ./init.sh "aws"     "tokyo" ""${HOME}/.aws/credentials""
$ ./init.sh "gcp"     "tokyo" "${HOME}/.ssh/google-credential-cloudbarista.json"
```

* Create a cluster

```
$ ./create-cluster-2.sh "aws" "tokyo" "gcp" "tokyo"
```

* Delete a cluster

```
$ ./delete-cluster.sh
```



## Use Case #3 : Triple-Clouds Provisioning

* Set `CLUSTER` environment variable

```
$ export CLUSTER="cb-cluster-3"
```


* Create a connection info

```
$ ./init.sh "aws"     "tokyo"     "${HOME}/.aws/credentials"
$ ./init.sh "gcp"     "london"    "${HOME}/.ssh/google-credential-cloudbarista.json"
$ ./init.sh "tencent" "singapore" "${HOME}/.tccli/default.credential"

```


* Create a cluster

```
$ ./create-cluster-3.sh "aws" "tokyo" "gcp" "london" "tencent" "seoul"
```

* Delete a cluster

```
$ ./delete-cluster.sh
```


## Use Case #4 : Double-Clouds Provisioning & Add Node

* Set `CLUSTER` environment variable

```
$ export CLUSTER="cb-cluster-4"
```


* Create a connection info

```
$ ./init.sh "aws"     "tokyo"     "${HOME}/.aws/credentials"
$ ./init.sh "gcp"     "london"    "${HOME}/.ssh/google-credential-cloudbarista.json"
$ ./init.sh "tencent" "singapore" "${HOME}/.tccli/default.credential"
```


* Create a cluster

```
$ ./create-cluster-2.sh "aws" "tokyo" "tencent" "singapore"
```


* Add a node

```
$ ./add-node.sh "gcp" "london"
```

* Delete a cluster

```
$ ./delete-cluster.sh
```


## 기타 스크립트 

* Delete a Cluster

```
$ ./delete-cluster.sh 

$ ./delete-cluster.sh "cb-cluster-1"
```

* Get cluster list

```
$ ./list-cluster.sh
```


* verify MCIR

```
$ ./list-mcir.sh

or

$ cat output/driver.json
$ cat output/region.json
$ cat output/credential.json
$ cat output/connectionconfig.json
$ cat output/ns.json
```



## 앱 설치 검증

```
$ export KUBECONFIG="$(pwd)/kubeconfig/cb-cluster.yaml"
```

### metrics-server 설치
> https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.3.6/components.yaml

* Prerequisite : 방화벽 포트 전체 열어주기
```
$ kubectl apply -f yaml/metrics-server-0.3.7.yaml
$ kubectl get apiservice -w
$ kubectl get --raw /apis/metrics.k8s.io/v1beta1/nodes
```

### kubernetes-dahsboard
> https://github.com/kubernetes/dashboard

```
$ kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.4.0/aio/deploy/recommended.yaml
$ kubectl get po -n kubernetes-dashboard

$ kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kube-system
EOF

$ kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep admin-user | awk '{print $1}')
$ kubectl proxy
```

* open your browser `http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/.`


### weavescope
> https://cloud.weave.works/k8s/scope.yaml?k8s-version=$(kubectl version | base64 | tr -d '\n')

* deploy

```
$ kubectl apply -f yaml/scope.yaml
$ kubectl get po -n weave -w
```


```
$ kubectl port-forward svc/weave-scope-app 8080:80 -n weave
```

* open your browser `http://localhost:8080/`




### sock-shop
> https://raw.githubusercontent.com/itnpeople/k8s.docs/master/demo/yaml/sock-shop.yaml


* deploy

```
$ kubectl apply -f yaml/sock-shop.yaml

# verify
$ kubectl get po -n sock-shop -w
```

* open your browser `http://<Public-IP>:30001/`




## Kubernetes 노드긴 통신 검증 예


```
$ ./httpbin3.sh "$(kubectl get node |  awk 'FNR==2 {print $1}')" "$(kubectl get node |  awk 'FNR==3 {print $1}')" "$(kubectl get node |  awk 'FNR==4 {print $1}')"
$ kubectl get po -w -o wide
```


```
$ kubectl exec -it httpbin-1  -- curl http://httpbin-2/ip
$ kubectl exec -it httpbin-1  -- curl http://httpbin-3/ip

$ kubectl exec -it httpbin-2  -- curl http://httpbin-1/ip
$ kubectl exec -it httpbin-2  -- curl http://httpbin-3/ip

$ kubectl exec -it httpbin-3  -- curl http://httpbin-1/ip
$ kubectl exec -it httpbin-3  -- curl http://httpbin-2/ip
```


## Clean-up 

```
$ docker stop cb-mcks cb-tumblebug cb-spider
$ rm -rf data/mcks/meta_db/ data/spider/meta_db/ data/tumblebug/meta_db/
$ rm -f kubeconfig/* output/* ssh/*
```

### Cloud Provider 별 수동 제거

*  AWS

  * VPC > VCP
  * EC2 > 네트워크 및 보안 > 키페어

* GCP

  * VPC 네트워크 > VCP 네트워크

* Azure

  * VCP (가상 네트워크)
  * SecurityGroup (네트워크 보안 그룹)

* Alibaba
> TODO

* Tencent

  * (Product) Virtual Private Cloud > VPC
  * (Product) Cloud Virtual Machine > SSH KEY
  * (Product) Virtual Private Cloud > Security > Security Group

* OpenStack
> TODO
