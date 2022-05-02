# Testing Lab.

## Using `cbctl`
> https://github.com/itnpeople/cbctl

* Initialize (aws, gcp, azure)
```
$ cbctl namespace create acornsoft

$ cbctl driver create aws
$ cbctl driver create gcp
$ cbctl driver create azure
$ cbctl driver list

$ source ./examples/credentials.sh \
  aws="${HOME}/.aws/credentials" \
  gcp="${HOME}/.ssh/google-credential-cloudbarista.json" \
  azure="${HOME}/.azure/azure-credential-cloudbarista.json"
$ cbctl credential create credential-aws --csp aws --secret-id "$AWS_SECRET_ID" --secret "$AWS_SECRET_KEY"
$ cbctl credential create credential-gcp --csp gcp --client-email "$GCP_SA" --project-id "$GCP_PROJECT" --private-key "$GCP_PKEY"
$ cbctl credential create credential-azure --csp azure --secret-id "$AZURE_CLIENT_ID" --secret "$AZURE_CLIENT_SECRET" --subscription "$AZURE_SUBSCRIPTION_ID" --tenant "$AZURE_TENANT_ID"
$ cbctl credential list

$ cbctl region create region-aws-tokyo --csp aws --region ap-northeast-1 --zone ap-northeast-1a 
$ cbctl region create region-gcp-tokyo --csp gcp --region asia-northeast1 --zone asia-northeast1-a
$ cbctl region create region-azure-tokyo --csp azure --location japaneast --resource-group cb-mcks
$ cbctl region list

$ cbctl connection create config-aws-tokyo --csp aws --region region-aws-tokyo --credential credential-aws
$ cbctl connection create config-gcp-tokyo --csp gcp --region region-gcp-tokyo --credential credential-gcp
$ cbctl connection create config-azure-tokyo --csp azure --region region-azure-tokyo --credential credential-azure
$ cbctl connection list

$ cbctl connection test config-aws-tokyo
$ cbctl connection test config-gcp-tokyo
$ cbctl connection test config-azure-tokyo
```

* create a cluster (azure + aws)
```
$ cbctl cluster create -f - <<EOF
name: cb-cluster
label: lab.
description: create a cluster test
controlPlane:
  - connection: config-azure-tokyo
    count: 1
    spec: Standard_B2s
worker:
  - connection: config-aws-tokyo
    count: 1
    spec: t2.medium
config:
  kubernetes:
    networkCni: calico
    podCidr: 10.244.0.0/16
    serviceCidr: 10.96.0.0/12
    serviceDnsDomain: cluster.local
EOF

$ cbctl cluster update-kubeconfig cb-cluster
$ kubectl get node -o wide

$ cbctl node get-key  c-1-8mbil --cluster cb-cluster  > ssh/cb-cluster.pem
$ chmod 400 ssh/cb-cluster.pem
$ ssh -i ssh/cb-cluster.pem cb-user@52.196.137.231
```

* add nodes 
```
$ cbctl node add --cluster cb-cluster --worker-connection="config-aws-tokyo" --worker-count="1" --worker-spec="t2.medium"
$ cbctl node add --cluster cb-cluster --worker-connection="config-gcp-tokyo" --worker-count="1" --worker-spec="e2-highcpu-4"
$ cbctl node add --cluster cb-cluster --worker-connection="config-azure-tokyo" --worker-count="1" --worker-spec="Standard_B2s"
$ cbctl node add --cluster cb-cluster --worker-connection="config-ibm-tokyo" --worker-count="1" --worker-spec="bx2-2x8"
```

* delete a node
```
$ cbctl node delete w-1-d4rra --cluster cb-cluster
```


* delete a cluster
```
$ cbctl cluster delete cb-cluster
```

### Use cases

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

$ cbctl cluster update-kubeconfig cb-cluster
$ kubectl get node -o wide

$ MASTER="$(kubectl get node -o custom-columns=:metadata.name --no-headers | awk 'NR==1 { print;}')"
$ WORKER="$(kubectl get node -o custom-columns=:metadata.name --no-headers | awk 'NR==2 { print;}')"
$ MASTER_IP="$(kubectl get node -o custom-columns=:status.addresses[0].address --no-headers | awk 'NR==1 { print;}')"
$ WORKER_IP="$(kubectl get node -o custom-columns=:status.addresses[0].address --no-headers | awk 'NR==2 { print;}')"
$ echo "MASTER=\"${MASTER}\"; WORKER=\"${WORKER}\"; MASTER_IP=\"${MASTER_IP}\"; WORKER_IP=\"${WORKER_IP}\""

$ cbctl node get-key ${MASTER}  --cluster cb-cluster  > ssh/${MASTER}.pem
$ chmod 400 ssh/${MASTER}.pem
$ ssh -i ssh/${MASTER}.pem cb-user@${MASTER_IP}


$ cbctl node get-key ${WORKER} --cluster cb-cluster  > ssh/${WORKER}.pem
$ chmod 400 ssh/${WORKER}.pem
$ ssh -i ssh/${WORKER}.pem cb-user@${WORKER_IP}
```

## JMeter Testing (kubernetes)
> https://jmeter.apache.org/
> https://hub.docker.com/r/bitnami/jenkins
> https://github.com/bitnami/bitnami-docker-jenkins

### Installation

#### MKCK 및 Jenkin 배포

* deployment

```
$ kubectl apply -f yaml/mcks/mcks.yaml
$ kubectl apply -f yaml/jenkins-jmeter.yaml
```

* CSP별 Credentials 정보 환경변수 파일 생성

```
$ source "${HOME}/.ssh/openstack-openrc.sh"
$ ./credentials.sh \
  aws="${HOME}/.aws/credentials" \
  gcp="${HOME}/.ssh/google-credential-cloudbarista.json" \
  azure="${HOME}/.azure/azure-credential-cloudbarista.json" \
  alibaba="${HOME}/.ssh/alibaba_accesskey.csv" \
  tencent="${HOME}/.tccli/default.credential" \
  ibm="${HOME}/.ssh/ibm-apikey.json" \
  cloudit="${HOME}/.ssh/cloudit-credential.sh" > credentials
$ chmod +x credentials
```

*  JMeter Test 파일 Jenkins Pod에 업로드
```
$ POD="$(kubectl get po -l app.kubernetes.io/component=jenkins-jmeter -o jsonpath="{.items[*].metadata.name}")"

# 이전 파일 삭제 & 업로드
$ kubectl exec -it $POD -- rm -f /opt/bitnami/jmeter/mcks.jmx /opt/bitnami/jmeter/mcks.jtl /opt/bitnami/jmeter/credentials
$ kubectl cp mcks.jmx $POD:/opt/bitnami/jmeter
$ kubectl cp credentials $POD:/opt/bitnami/jmeter

# 확인
$ kubectl exec -it $POD -- ls -l /opt/bitnami/jmeter
```

#### Jenkin Web UI에서 빌드 프로젝트 생성
* open in your browser `http://<cluster-ip>:30084/` 
* enter userid, password `admin`,`admin1234`
* Jenkins 빌드 추가 (Execute shell)

```
$ export HOST="mcks"
$ source /opt/bitnami/jmeter/credentials
$ jmeter -n -t /opt/bitnami/jmeter/mcks.jmx -l /opt/bitnami/jmeter/$(date "+%Y%m%d").jtl
```

### 테스트 실행

* Jenkins Web UI에서 Build 수행

* 빌드 결과 다운로드

```
$ rm -f mcks.jtl
$ POD="$(kubectl get po -l app.kubernetes.io/component=jenkins-jmeter -o jsonpath="{.items[*].metadata.name}")"
$ kubectl exec -it $POD -- cat /opt/bitnami/jmeter/$(date "+%Y%m%d").jtl > mcks.jtl
$ cat mcks.jtl
```

* JMeter 등으로 결과 확인 (mcks.jtl)


### Developments

#### Docker build

```
$ docker build ./images/jenkins-jmeter --tag honester/jenkins-jmeter:latest
```

#### JMeter jmx

* `credentials` 파일이 없다면 `credentials.sh` 스크립트 실행하여 실행
```
$ source ./credentials.sh \
  aws="${HOME}/.aws/credentials" \
  gcp="${HOME}/.ssh/google-credential-cloudbarista.json" \
  azure="${HOME}/.azure/azure-credential-cloudbarista.json" \
  alibaba="${HOME}/.ssh/alibaba_accesskey.csv" \
  tencent="${HOME}/.tccli/default.credential" \
  ibm="${HOME}/.ssh/ibm-apikey.json" \
  openstack="${HOME}/.ssh/openstack-openrc.sh"
```

* JMeter 디자이너 오픈

```
$ export HOST="localhost"
$ source ./credentials
$ jmeter -t mcks.jmx
```


### Distributed Testing (docker)


#### make images

```
$ docker build ./images/jmbase --tag honester/jmbase:latest
$ docker build ./images/jmmaster --tag honester/jmmaster:latest
$ docker build ./images/jmserver --tag honester/jmserver:latest


$ docker push honester/jenkins-jmeter:latest
```

#### verify

* docker run

```
$ docker run -dit --rm --name slave01 honester/jmserver /bin/bash
$ docker run -dit --name slave02 honester/jmserver /bin/bash
$ docker run -dit --name slave03 honester/jmserver /bin/bash
$ docker run -dit --name master honester/jmmaster /bin/bash
```

* 테스트용 jmx 파일 업로드
```
$ docker exec -i master sh -c 'cat > /jmeter/simple-test.jmx' < simple-test.jmx
```

* 테스트용 jmx 실행/결과확인

```
$ docker exec -i master jmeter -n -t /jmeter/simple-test.jmx

Creating summariser <summary>
Created the tree successfully using /jmeter/simple-test.jmx
Starting standalone test @ Thu Dec 02 02:27:54 UTC 2021 (1638412074363)
Waiting for possible Shutdown/StopTestNow/HeapDump/ThreadDump message on port 4445
summary =      1 in 00:00:01 =    0.9/s Avg:   945 Min:   945 Max:   945 Err:     0 (0.00%)
Tidying up ...    @ Thu Dec 02 02:27:55 UTC 2021 (1638412075472)
... end of run
```

* slave IP 확인

```
$ docker inspect --format '{{ .Name }} => {{ .NetworkSettings.IPAddress }}' $(sudo docker ps -a -q)

/master => 172.17.0.5
/slave03 => 172.17.0.4
/slave02 => 172.17.0.3
/slave01 => 172.17.0.2
```

* master jmx 실행/결과확인

```
$ docker exec -i master jmeter -n -t /jmeter/simple-test.jmx -R172.17.0.2,172.17.0.3,172.17.0.4 -Dserver.rmi.ssl.disable=true

Creating summariser <summary>
Created the tree successfully using /jmeter/simple-test.jmx
Configuring remote engine: 172.17.0.2
Configuring remote engine: 172.17.0.3
Configuring remote engine: 172.17.0.4
Starting distributed test with remote engines: [172.17.0.4, 172.17.0.2, 172.17.0.3] @ Thu Dec 02 02:33:22 UTC 2021 (1638412402426)
Remote engines have been started:[172.17.0.4, 172.17.0.2, 172.17.0.3]
Waiting for possible Shutdown/StopTestNow/HeapDump/ThreadDump message on port 4445
summary =      3 in 00:00:01 =    2.4/s Avg:   777 Min:   761 Max:   800 Err:     0 (0.00%) 
Tidying up remote @ Thu Dec 02 02:33:24 UTC 2021 (1638412404089)
... end of run
```


## Test case #1


```
$ git clone https://github.com/itnpeople/cb-mcks-lab.git
$ cd cb-mcks-lab/testing
$ ./startup.sh
```

```
$ source ./credentials.sh \
  aws="${HOME}/.aws/credentials" \
  gcp="${HOME}/.ssh/google-credential-cloudbarista.json" \
  azure="${HOME}/.azure/azure-credential-cloudbarista.json" \
  alibaba="${HOME}/.ssh/alibaba_accesskey.csv" \
  tencent="${HOME}/.tccli/default.credential"

$ export HOST="localhost"
$ source ./credentials
```

```
$ jmeter -n -t mcks-c1.jmx -l mcks-c1-$(date "+%Y%m%d").jtl
```

```
$ docker logs cb-mcks -f
```

```
$ ./save-ssh-kubeconfig.sh aws tokyo
$ export KUBECONFIG=$(pwd)/kubeconfig/cb-cluster.yaml
$ kubectl get node -o wide

NAME         STATUS   ROLES    AGE     VERSION   INTERNAL-IP      EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION       CONTAINER-RUNTIME
c-1-rtep4    Ready    master   15m     v1.18.9   52.197.103.14    <none>        Ubuntu 18.04.5 LTS   5.3.0-1035-aws       docker://19.3.11
c-2-guaqn    Ready    master   14m     v1.18.9   13.231.208.44    <none>        Ubuntu 18.04.5 LTS   5.3.0-1035-aws       docker://19.3.11
c-3-78kc2    Ready    master   13m     v1.18.9   52.199.96.7      <none>        Ubuntu 18.04.5 LTS   5.3.0-1035-aws       docker://19.3.11
w-1-scgr7    Ready    <none>   12m     v1.18.9   54.95.52.15      <none>        Ubuntu 18.04.5 LTS   5.3.0-1035-aws       docker://19.3.11
w-10-fslu8   Ready    <none>   12m     v1.18.9   35.77.85.43      <none>        Ubuntu 18.04.5 LTS   5.3.0-1035-aws       docker://19.3.11
w-11-cm0qj   Ready    <none>   12m     v1.18.9   34.146.33.119    <none>        Ubuntu 18.04.5 LTS   5.4.0-1028-gcp       docker://19.3.11
w-12-0qw30   Ready    <none>   12m     v1.18.9   34.146.206.253   <none>        Ubuntu 18.04.5 LTS   5.4.0-1028-gcp       docker://19.3.11
w-13-fwdvl   Ready    <none>   12m     v1.18.9   34.84.166.28     <none>        Ubuntu 18.04.5 LTS   5.4.0-1028-gcp       docker://19.3.11
w-14-4wv6q   Ready    <none>   12m     v1.18.9   35.194.124.8     <none>        Ubuntu 18.04.5 LTS   5.4.0-1028-gcp       docker://19.3.11
w-15-gulq1   Ready    <none>   11m     v1.18.9   35.187.194.61    <none>        Ubuntu 18.04.5 LTS   5.4.0-1028-gcp       docker://19.3.11
w-16-dfbw9   Ready    <none>   11m     v1.18.9   34.84.129.58     <none>        Ubuntu 18.04.5 LTS   5.4.0-1028-gcp       docker://19.3.11
w-17-ztx1l   Ready    <none>   11m     v1.18.9   35.200.84.92     <none>        Ubuntu 18.04.5 LTS   5.4.0-1028-gcp       docker://19.3.11
w-18-dj6o4   Ready    <none>   11m     v1.18.9   34.84.122.225    <none>        Ubuntu 18.04.5 LTS   5.4.0-1028-gcp       docker://19.3.11
w-19-qjgjt   Ready    <none>   11m     v1.18.9   35.187.217.120   <none>        Ubuntu 18.04.5 LTS   5.4.0-1028-gcp       docker://19.3.11
w-2-oljmy    Ready    <none>   11m     v1.18.9   18.183.105.22    <none>        Ubuntu 18.04.5 LTS   5.3.0-1035-aws       docker://19.3.11
w-20-969b5   Ready    <none>   10m     v1.18.9   34.84.130.165    <none>        Ubuntu 18.04.5 LTS   5.4.0-1028-gcp       docker://19.3.11
w-21-ofwx2   Ready    <none>   10m     v1.18.9   20.210.222.227   <none>        Ubuntu 18.04.6 LTS   5.4.0-1064-azure     docker://19.3.11
w-22-7st3v   Ready    <none>   10m     v1.18.9   20.210.247.246   <none>        Ubuntu 18.04.6 LTS   5.4.0-1064-azure     docker://19.3.11
w-23-23qun   Ready    <none>   10m     v1.18.9   52.140.198.124   <none>        Ubuntu 18.04.6 LTS   5.4.0-1064-azure     docker://19.3.11
w-24-35kkx   Ready    <none>   10m     v1.18.9   20.210.227.180   <none>        Ubuntu 18.04.6 LTS   5.4.0-1064-azure     docker://19.3.11
w-25-5dh47   Ready    <none>   10m     v1.18.9   20.210.228.129   <none>        Ubuntu 18.04.6 LTS   5.4.0-1064-azure     docker://19.3.11
w-26-61ffo   Ready    <none>   10m     v1.18.9   20.210.231.176   <none>        Ubuntu 18.04.6 LTS   5.4.0-1064-azure     docker://19.3.11
w-27-qpkom   Ready    <none>   9m55s   v1.18.9   20.210.222.208   <none>        Ubuntu 18.04.6 LTS   5.4.0-1064-azure     docker://19.3.11
w-28-0psq6   Ready    <none>   9m47s   v1.18.9   52.140.195.60    <none>        Ubuntu 18.04.6 LTS   5.4.0-1064-azure     docker://19.3.11
w-29-v66rh   Ready    <none>   9m38s   v1.18.9   20.210.231.178   <none>        Ubuntu 18.04.6 LTS   5.4.0-1064-azure     docker://19.3.11
w-3-aobk5    Ready    <none>   9m29s   v1.18.9   18.183.75.143    <none>        Ubuntu 18.04.5 LTS   5.3.0-1035-aws       docker://19.3.11
w-30-5vanm   Ready    <none>   9m19s   v1.18.9   20.210.222.206   <none>        Ubuntu 18.04.6 LTS   5.4.0-1064-azure     docker://19.3.11
w-31-vzol0   Ready    <none>   9m5s    v1.18.9   8.211.142.80     <none>        Ubuntu 18.04.5 LTS   4.15.0-144-generic   docker://19.3.11
w-32-yo261   Ready    <none>   8m55s   v1.18.9   8.211.141.49     <none>        Ubuntu 18.04.5 LTS   4.15.0-144-generic   docker://19.3.11
w-33-hb1sl   Ready    <none>   8m46s   v1.18.9   8.211.140.42     <none>        Ubuntu 18.04.5 LTS   4.15.0-144-generic   docker://19.3.11
w-34-di98o   Ready    <none>   8m36s   v1.18.9   8.211.140.234    <none>        Ubuntu 18.04.5 LTS   4.15.0-144-generic   docker://19.3.11
w-35-juqcr   Ready    <none>   8m26s   v1.18.9   8.211.142.146    <none>        Ubuntu 18.04.5 LTS   4.15.0-144-generic   docker://19.3.11
w-36-0i6th   Ready    <none>   8m16s   v1.18.9   8.211.142.118    <none>        Ubuntu 18.04.5 LTS   4.15.0-144-generic   docker://19.3.11
w-37-1x3k1   Ready    <none>   8m7s    v1.18.9   8.211.137.13     <none>        Ubuntu 18.04.5 LTS   4.15.0-144-generic   docker://19.3.11
w-38-i0skl   Ready    <none>   7m56s   v1.18.9   8.211.140.240    <none>        Ubuntu 18.04.5 LTS   4.15.0-144-generic   docker://19.3.11
w-39-b3yqq   Ready    <none>   7m47s   v1.18.9   8.211.143.111    <none>        Ubuntu 18.04.5 LTS   4.15.0-144-generic   docker://19.3.11
w-4-uhndn    Ready    <none>   7m42s   v1.18.9   13.114.133.175   <none>        Ubuntu 18.04.5 LTS   5.3.0-1035-aws       docker://19.3.11
w-40-yfz06   Ready    <none>   7m28s   v1.18.9   8.211.138.155    <none>        Ubuntu 18.04.5 LTS   4.15.0-144-generic   docker://19.3.11
w-41-f5a31   Ready    <none>   7m18s   v1.18.9   43.133.179.25    <none>        Ubuntu 18.04.4 LTS   4.15.0-159-generic   docker://19.3.11
w-42-f8ttq   Ready    <none>   7m8s    v1.18.9   43.133.212.40    <none>        Ubuntu 18.04.4 LTS   4.15.0-159-generic   docker://19.3.11
w-43-b1ibt   Ready    <none>   6m59s   v1.18.9   43.133.26.63     <none>        Ubuntu 18.04.4 LTS   4.15.0-159-generic   docker://19.3.11
w-44-y8wgv   Ready    <none>   6m49s   v1.18.9   43.128.238.147   <none>        Ubuntu 18.04.4 LTS   4.15.0-159-generic   docker://19.3.11
w-45-n5s6q   Ready    <none>   6m38s   v1.18.9   43.133.175.76    <none>        Ubuntu 18.04.4 LTS   4.15.0-159-generic   docker://19.3.11
w-46-wlhcq   Ready    <none>   6m28s   v1.18.9   43.130.233.42    <none>        Ubuntu 18.04.4 LTS   4.15.0-159-generic   docker://19.3.11
w-47-4i1vo   Ready    <none>   6m18s   v1.18.9   43.133.193.27    <none>        Ubuntu 18.04.4 LTS   4.15.0-159-generic   docker://19.3.11
w-48-ce5co   Ready    <none>   6m8s    v1.18.9   43.133.208.45    <none>        Ubuntu 18.04.4 LTS   4.15.0-159-generic   docker://19.3.11
w-49-9acfo   Ready    <none>   5m58s   v1.18.9   43.133.187.125   <none>        Ubuntu 18.04.4 LTS   4.15.0-159-generic   docker://19.3.11
w-5-fwhcv    Ready    <none>   5m54s   v1.18.9   3.112.216.111    <none>        Ubuntu 18.04.5 LTS   5.3.0-1035-aws       docker://19.3.11
w-50-pf3aa   Ready    <none>   5m40s   v1.18.9   43.133.214.136   <none>        Ubuntu 18.04.4 LTS   4.15.0-159-generic   docker://19.3.11
w-6-bukh6    Ready    <none>   5m35s   v1.18.9   18.179.37.160    <none>        Ubuntu 18.04.5 LTS   5.3.0-1035-aws       docker://19.3.11
w-7-jivjh    Ready    <none>   5m27s   v1.18.9   18.183.236.240   <none>        Ubuntu 18.04.5 LTS   5.3.0-1035-aws       docker://19.3.11
w-8-uocwn    Ready    <none>   5m17s   v1.18.9   18.183.242.93    <none>        Ubuntu 18.04.5 LTS   5.3.0-1035-aws       docker://19.3.11
w-9-nl4tu    Ready    <none>   5m8s    v1.18.9   13.231.237.194   <none>        Ubuntu 18.04.5 LTS   5.3.0-1035-aws       docker://19.3.11
```

### metrics-server 설치

```
$ kubectl apply -f yaml/metrics-server-v0.5.1-kubelet-insecure-tls.yaml
$ kubectl get apiservice -w

NAME                                   SERVICE                      AVAILABLE   AGE
v1.                                    Local                        True        19m
v1.admissionregistration.k8s.io        Local                        True        19m
v1.apiextensions.k8s.io                Local                        True        19m
v1.apps                                Local                        True        19m
v1.authentication.k8s.io               Local                        True        19m
v1.authorization.k8s.io                Local                        True        19m
v1.autoscaling                         Local                        True        19m
v1.batch                               Local                        True        19m
v1.coordination.k8s.io                 Local                        True        19m
v1.crd.projectcalico.org               Local                        True        16m
v1.networking.k8s.io                   Local                        True        19m
v1.rbac.authorization.k8s.io           Local                        True        19m
v1.scheduling.k8s.io                   Local                        True        19m
v1.storage.k8s.io                      Local                        True        19m
v1beta1.admissionregistration.k8s.io   Local                        True        19m
v1beta1.apiextensions.k8s.io           Local                        True        19m
v1beta1.authentication.k8s.io          Local                        True        19m
v1beta1.authorization.k8s.io           Local                        True        19m
v1beta1.batch                          Local                        True        19m
v1beta1.certificates.k8s.io            Local                        True        19m
v1beta1.coordination.k8s.io            Local                        True        19m
v1beta1.discovery.k8s.io               Local                        True        19m
v1beta1.events.k8s.io                  Local                        True        19m
v1beta1.extensions                     Local                        True        19m
v1beta1.metrics.k8s.io                 kube-system/metrics-server   True        51s
v1beta1.networking.k8s.io              Local                        True        19m
v1beta1.node.k8s.io                    Local                        True        19m
v1beta1.policy                         Local                        True        19m
v1beta1.rbac.authorization.k8s.io      Local                        True        19m
v1beta1.scheduling.k8s.io              Local                        True        19m
v1beta1.storage.k8s.io                 Local                        True        19m
v2beta1.autoscaling                    Local                        True        19m
v2beta2.autoscaling                    Local                        True        19m


$ kubectl get --raw /apis/metrics.k8s.io/v1beta1/nodes
```

### Kore-board

```
$ kubectl apply -f https://raw.githubusercontent.com/kore3lab/dashboard/master/scripts/install/metrics-server/metrics-server-v0.5.1-kubelet-insecure-tls.yaml
$ kubectl apply -f https://raw.githubusercontent.com/kore3lab/dashboard/master/scripts/install/kuberntes/recommended.yaml
```
* Open your browser 'http:<cluster-ip>:30080/
* enter `kore3lab` token string


### weavescope

* deploy

```
$ kubectl apply -f yaml/scope.yaml
$ kubectl get po -o wide -n weave -w
```

```
$ kubectl port-forward svc/weave-scope-app 8080:80 -n weave
```

* open your browser `http://localhost:8080/`


## httpbin testring

```
./httpbin3.sh c-1-0wfxe w-1-nh9jv w-9-glrt3


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


## 수동 검증

* kube-system 확인

```
$ kubectl get node -o wide
$ kubectl get po -n kube-system
```

* node annotation 확인

```
$ kubectl get node c-3-qfs8w -o yaml

# Kilo

flannel.alpha.coreos.com/backend-data: '{"VNI":1,"VtepMAC":"46:f3:bd:26:12:07"}'
flannel.alpha.coreos.com/backend-type: vxlan
flannel.alpha.coreos.com/kube-subnet-manager: "true"
flannel.alpha.coreos.com/public-ip: 13.112.188.105
flannel.alpha.coreos.com/public-ip-overwrite: 13.112.188.105
kilo.squat.ai/discovered-endpoints: '{}'
kilo.squat.ai/endpoint: 13.112.188.105:51820
kilo.squat.ai/force-endpoint: 13.112.188.105:51820
kilo.squat.ai/granularity: location
kilo.squat.ai/internal-ip: 192.168.1.154/24
kilo.squat.ai/key: PjwGRJlad/T3Qrv4qKGCtYowk8adrMmmLfld/SZvBj8=
kilo.squat.ai/last-seen: "1640657831"
kilo.squat.ai/location: aws-ap-northeast-1
kilo.squat.ai/persistent-keepalive: "25"
kilo.squat.ai/wireguard-ip: ""

# Canal

flannel.alpha.coreos.com/backend-data: '{"VNI":1,"VtepMAC":"76:ca:4b:f9:0c:4e"}'
flannel.alpha.coreos.com/backend-type: vxlan
flannel.alpha.coreos.com/kube-subnet-manager: "true"
flannel.alpha.coreos.com/public-ip: 34.146.206.253
flannel.alpha.coreos.com/public-ip-overwrite: 34.146.206.253
projectcalico.org/IPv4Address: 192.168.1.3/32
projectcalico.org/IPv4IPIPTunnelAddr: 10.244.1.1
```


* /lib/systemd/system/mcks-bootstrap 파일 확인
  * OpenStack  인 경우는 `PUBLIC_IP` 변수에 고정 IP, 나머지는 CSP는 `$(dig +short myip.opendns.com @resolver1.opendns.com)`


* httpbin3 테스트



* shutdown 테스트 
  * CSP 별 Web-Console 에서 정지>시작 후 IP 변경 확인 후 `kubectl get node -o wide` 로 변경 IP 확인
  * httpbin 테스트
