# CB-Ladybug Lab.
* v0.4.0-cafemocha
* https://github.com/cloud-barista/cb-spider/wiki/How-to-get-CSP-Credentials


## 실행

* docker run
```
$ ./startup.sh
```

* 로그

```
$ docker logs cb-ladybug -f
```


## Single-Cloud Provisioning

### 환경 변수 정의 (공통)

* CSP (aws, gcp, azure)
```
$ export CSP="aws"
```

* 리전 (seoul, tokyo, singapore, usca, london)

```
$ export R="seoul"
```

* CSP별 credential 파일 정의

```
# 예제
$ export FILE="${HOME}/.aws/credentials"
$ export FILE="$(pwd)/google-credential-cloudbarista.json"
$ export FILE="$(pwd)/azure-credential-cloudbarista.json"
```

### Create a cluster

* create a connection info

```
$ ./init.sh "${CSP}" "${R}" "${FILE}"

$ cat output/driver.json
$ cat output/region.json
$ cat output/credential.json
$ cat output/connectionconfig.json
$ cat output/ns.json
```

* Create a cluster

```
$ ./create-cluster.sh "${CSP}" "${R}"
```


* 메타 데이터 조회
```
$ ./output/clusters.json
```

### 클라이언트 연동 테스트

* SSH 연결('public ip'는 CSP별 관리 console 에서 조회)

```
$ ssh -i $(pwd)/ssh/${CSP}-${R}.pem cb-user@<PUBLIC_IP>
```

* kubectl 로 노드 조회

```
$ export KUBECONFIG=$(pwd)/kubeconfig/${CSP}-${R}.yaml
$ kubectl get nodes
```



## Multi-Cloud Provisioning
> 3 Regins

### 환경 변수 정의

* 클라우드별 credential 파일 정의

```
$ export AWS_FILE="${HOME}/.aws/credentials"
$ export GCP_FILE="$(pwd)/google-credential-cloudbarista.json"
$ export AZURE_FILE="$(pwd)/azure-credential-cloudbarista.json"
```

* 클라우드, 리전 정의

```
$ CSP_1="aws"; R_1="tokyo"
$ CSP_2="aws"; R_2="singapore"
$ CSP_3="gcp"; R_3="tokyo"
```

* create a connection info

```
$ ./init.sh "${CSP_1}" "${R_1}" "${AWS_FILE}"
$ ./init.sh "${CSP_2}" "${R_2}" "${AWS_FILE}"
$ ./init.sh "${CSP_3}" "${R_3}" "${GCP_FILE}"

$ cat output/driver.json
$ cat output/region.json
$ cat output/credential.json
$ cat output/connectionconfig.json
$ cat output/ns.json
```

### 클러스터 생성

```
$ ./create-cluster-3.sh "${CSP_1}" "${R_1}" "${CSP_2}" "${R_2}" "${CSP_3}" "${R_3}"
```


### 클라이언트 연동 테스트

* SSH 연결('public ip'는 CSP별 관리 console 에서 조회)

```
$ ssh -i $(pwd)/ssh/${CSP_1}-${R_1}.pem cb-user@<PUBLIC_IP>
```

* kubectl 로 노드 조회

```
$ export KUBECONFIG=$(pwd)/kubeconfig/${CSP_1}-${R_1}.yaml
$ kubectl get nodes
```

### 클러스터 삭제

```
$ ./delete-cluster.sh "${CSP_1}" "${R_1}"
```


## 앱 설치 테스트

### metrics-server 설치
> https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.3.6/components.yaml

* Prerequisite : 방화벽 포트 전체 열어주기
```
$ kubectl apply -f yaml/metrics-server-0.3.7.yaml
$ kubectl get apiservice -w
$ kubectl get --raw /apis/metrics.k8s.io/v1beta1/nodes
```


### weavescope

```
$ kubectl apply -f "https://cloud.weave.works/k8s/scope.yaml?k8s-version=$(kubectl version | base64 | tr -d '\n')"
```

### sock-shop

```
$ kubectl apply -f https://raw.githubusercontent.com/itnpeople/k8s.docs/master/demo/yaml/sock-shop.yaml
```






## Kubernetes 노드긴 통신 검증 예


```
./httpbin3.sh "ip-192-168-1-153" "ip-192-168-1-178" "ip-192-168-1-185"

$ kubectl exec -it httpbin-1  -- curl http://httpbin-2/ip
$ kubectl exec -it httpbin-1  -- curl http://httpbin-3/ip
$ kubectl exec -it httpbin-1  -- curl http://httpbin-4/ip
$ kubectl exec -it httpbin-1  -- curl http://httpbin-5/ip

$ kubectl exec -it httpbin-2  -- curl http://httpbin-1/ip
$ kubectl exec -it httpbin-2  -- curl http://httpbin-3/ip
$ kubectl exec -it httpbin-2  -- curl http://httpbin-4/ip
$ kubectl exec -it httpbin-2  -- curl http://httpbin-5/ip 

$ kubectl exec -it httpbin-3  -- curl http://httpbin-1/ip
$ kubectl exec -it httpbin-3  -- curl http://httpbin-2/ip
$ kubectl exec -it httpbin-3  -- curl http://httpbin-4/ip
$ kubectl exec -it httpbin-3  -- curl http://httpbin-5/ip
```


## Clean-up 


* 메타 데이터 삭제
```
$ docker stop cb-ladybug cb-tumblebug cb-spider
$ rm -rf data/ladybug/meta_db/ data/spider/meta_db/ data/tumblebug/meta_db/
$ rm -f kubeconfig/* output/* ssh/*
```
