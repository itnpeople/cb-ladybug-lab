# CB-Ladybug Lab.
* v0.4.0-cafemocha
* https://github.com/cloud-barista/cb-spider/wiki/How-to-get-CSP-Credentials


## 실행

* docker run
```
$ ./startup.sh
```

## 환경 변수 정의 (공통)

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

## Create a cluster


* create a connection info

```
$ ./init.sh "${CSP}" "${R}" "${FILE}"
```

* create a cluster

```
$ ./create-cluster.sh "${CSP}" "${R}"
```

* 로그

```
$ docker logs cb-ladybug -f
```

* 메타 데이터  조회
```
$ curl -sX GET http://localhost:8080/ladybug/ns/cb-${CSP}-namespace/clusters | jq
```


## 클라이언트 연동 테스트

* SSH 연결('public ip'는 CSP별 관리 console 에서 조회)

```
$ ssh -i $(pwd)/ssh/${CSP}-${R}.pem cb-user@<PUBLIC_IP>
```

* kubectl 로 노드 조회

```
$ export KUBECONFIG=$(pwd)/kubeconfig/${CSP}-${R}.yaml
$ kubectl get nodes
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

* delete a cluster

```
$ ./delete-cluster.sh "aws" "seoul"
```

* 메타 데이터 삭제
```
$ docker stop cb-ladybug cb-tumblebug cb-spider
$ rm -rf data/ladybug/meta_db/ data/spider/meta_db/ data/tumblebug/meta_db/
```
