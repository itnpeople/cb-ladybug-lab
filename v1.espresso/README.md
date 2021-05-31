# README

* v0.3.0-espresso

## 환경

```
./startup.sh
```

## create

```
export CSP="aws"
export CSP="gcp"

export R="seoul"
export R="tokyo"
export R="singapore"
export R="usca"
export R="london"

./init.sh
./create-cluster.sh
```

## SSH

```
curl -sX GET http://localhost:8080/ladybug/ns/cb-${CSP}-namespace/clusters | jq
ssh -i $(pwd)/ssh/${CSP}-${R}.pem ubuntu@
```

## kubeconfig

```
export KUBECONFIG=$(pwd)/kubeconfig/${CSP}-${R}.yaml
kubectl config set-cluster kubernetes --insecure-skip-tls-verify=true
```


## metrics-server 설치
> https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.3.6/components.yaml

* Prerequisite : 방화벽 포트 전체 열어주기
```
k apply -f yaml/metrics-server-0.3.7.yaml
k get apiservice -w
k get --raw /apis/metrics.k8s.io/v1beta1/nodes
```


## dashboard 설치

```
k create ns acornsoft-dashboard

cp ${KUBECONFIG} $(pwd)/kubeconfig/config
k create configmap acornsoft-dashboard-kubeconfig --from-file="$(pwd)/kubeconfig/config" -n acornsoft-dashboard
k apply -f yaml/acornsoft-dashboard.yaml
k get po -n acornsoft-dashboard -w
```

## weavescope /sock-shop

```
# weavescope
kubectl apply -f "https://cloud.weave.works/k8s/scope.yaml?k8s-version=$(kubectl version | base64 | tr -d '\n')"

# sock-shop
kubectl apply -f https://raw.githubusercontent.com/itnpeople/k8s.docs/master/demo/yaml/sock-shop.yaml
```

## Clean-up

```
./delete-cluster.sh
rm -rf data/ladybug/meta_db/ data/spider/meta_db/ data/tumblebug/meta_db/
```
* 수동 : vpc, 키페어 삭제

## 기타

### httpbin


```
./httpbin5.sh "ip-192-168-1-153" "ip-192-168-1-178" "ip-192-168-1-185" "ip-192-168-1-187" "ip-192-168-1-26"

k exec -it httpbin-1  -- curl http://httpbin-2/ip
k exec -it httpbin-1  -- curl http://httpbin-3/ip
k exec -it httpbin-1  -- curl http://httpbin-4/ip
k exec -it httpbin-1  -- curl http://httpbin-5/ip

k exec -it httpbin-2  -- curl http://httpbin-1/ip
k exec -it httpbin-2  -- curl http://httpbin-3/ip
k exec -it httpbin-2  -- curl http://httpbin-4/ip
k exec -it httpbin-2  -- curl http://httpbin-5/ip 

k exec -it httpbin-3  -- curl http://httpbin-1/ip
k exec -it httpbin-3  -- curl http://httpbin-2/ip
k exec -it httpbin-3  -- curl http://httpbin-4/ip
k exec -it httpbin-3  -- curl http://httpbin-5/ip

k exec -it httpbin-4  -- curl http://httpbin-1/ip
k exec -it httpbin-4  -- curl http://httpbin-2/ip
k exec -it httpbin-4  -- curl http://httpbin-3/ip
k exec -it httpbin-4  -- curl http://httpbin-5/ip


k exec -it httpbin-5  -- curl http://httpbin-1/ip
k exec -it httpbin-5  -- curl http://httpbin-2/ip
k exec -it httpbin-5  -- curl http://httpbin-3/ip
k exec -it httpbin-5  -- curl http://httpbin-4/ip
```



### tumblebug meta data

```
c_URL_TUMBLEBUG="http://localhost:1323/tumblebug"
c_NS="cb-${CSP}-namespace"
c_CT="Content-Type: application/json"
c_AUTH="Authorization: Basic $(echo -n default:default | base64)"

# 조회
curl -sX GET -H "${c_CT}" -H "${c_AUTH}" ${c_URL_TUMBLEBUG}/objects?key=/ns/${c_NS}/
./in  

curl -sX DELETE -H "${c_CT}" -H "${c_AUTH}" ${c_URL_TUMBLEBUG}/objects?key=/ns/${c_NS}/resources/securityGroup/cb-aws-india-allow-external
curl -sX DELETE -H "${c_CT}" -H "${c_AUTH}" ${c_URL_TUMBLEBUG}/objects?key=/ns/${c_NS}/resources/securityGroup/cb-india-allow-external


curl -sX GET -H "${c_CT}" -H "${c_AUTH}" -H "${c_AUTH}" ${c_URL_TUMBLEBUG}/ns/${c_NS}/resources/securityGroup | jq
curl -sX GET -H "${c_CT}" -H "${c_AUTH}" -H "${c_AUTH}" ${c_URL_TUMBLEBUG}/ns/${c_NS}/mcis | jq


curl -sX GET -H "${c_CT}" -H "${c_AUTH}" ${c_URL_TUMBLEBUG}/object?key=/ns/${c_NS}/securityGroup/cb-india-allow-external

"cb-aws-india-allow-external"

http://localhost:1323/tumblebug/objects?key=/cb-${CSP}-namespace/securityGroup
```



