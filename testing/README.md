# JMeter Testing (kubernetes)
> https://jmeter.apache.org/
> https://hub.docker.com/r/bitnami/jenkins
> https://github.com/bitnami/bitnami-docker-jenkins

## Installation

### MKCK 및 Jenkin 배포

* deployment

```
$ kubectl apply -f yaml/mcks/mcks.yaml
$ kubectl apply -f yaml/jenkins-jmeter.yaml
```

* CSP별 Credentials 정보 환경변수 파일 생성

```
$ ./credentials.sh \
  aws="${HOME}/.aws/credentials" \
  gcp="${HOME}/.ssh/google-credential-cloudbarista.json" \
  azure="${HOME}/.azure/azure-credential-cloudbarista.json" \
  alibaba="${HOME}/.ssh/alibaba_accesskey.csv" \
  tencent="${HOME}/.tccli/default.credential" \
  ibm="${HOME}/.ssh/ibm-apikey.json" \
  openstack="${HOME}/.ssh/openstack-openrc.sh" > credentials
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

### Jenkin Web UI에서 빌드 프로젝트 생성
* open in your browser `http://<cluster-ip>:30084/` 
* enter userid, password `admin`,`admin1234`
* Jenkins 빌드 추가 (Execute shell)

```
$ export HOST="mcks"
$ source /opt/bitnami/jmeter/credentials
$ jmeter -n -t /opt/bitnami/jmeter/mcks.jmx -l /opt/bitnami/jmeter/$(date "+%Y%m%d").jtl
```

## 테스트 실행

* Jenkins Web UI에서 Build 수행

* 빌드 결과 다운로드

```
$ rm -f mcks.jtl
$ POD="$(kubectl get po -l app.kubernetes.io/component=jenkins-jmeter -o jsonpath="{.items[*].metadata.name}")"
$ kubectl exec -it $POD -- cat /opt/bitnami/jmeter/$(date "+%Y%m%d").jtl > mcks.jtl
$ cat mcks.jtl
```

* JMeter 등으로 결과 확인 (mcks.jtl)


## Developments

### Docker build

```
$ docker build ./images/jenkins-jmeter --tag honester/jenkins-jmeter:latest
```

### JMeter jmx

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


## Distributed Testing (docker)


### make images

```
$ docker build ./images/jmbase --tag honester/jmbase:latest
$ docker build ./images/jmmaster --tag honester/jmmaster:latest
$ docker build ./images/jmserver --tag honester/jmserver:latest


$ docker push honester/jenkins-jmeter:latest
```

### verify

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