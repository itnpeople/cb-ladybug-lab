# Performance Test for Custom-Image

## HashiCorp Packer
> Packer v1.8.3

* Install Packer

```
brew tap hashicorp/tap
brew install hashicorp/tap/packer
```


```
cd packer
packer init .
```

```
source credentials.sh aws="${HOME}/.aws/credentials"
packer build mcks.pkr.hcl
```

* TB #1
> https://docs.aws.amazon.com/vpc/latest/userguide/default-vpc.html#create-default-vpc

```
VPCIdNotSpecified: No default VPC for this user

aws ec2 create-default-vpc
```

## Testing
> cb-mcks v0.6.1


```
$ curl -LO "https://github.com/itnpeople/cbctl/releases/download/$(curl -s https://api.github.com/repos/itnpeople/cbctl/releases/latest | grep tag_name | sed -E 's/.*"([^"]+)".*/\1/')/cbctl-darwin-amd64"
$ mv cbctl-darwin-amd64 /usr/local/bin/cbctl
$ chmod +x /usr/local/bin/cbctl
```

```
$ cbctl create driver aws
$ source credentials.sh  aws="${HOME}/.aws/credentials"
$ cbctl create credential credential-aws --csp aws --secret-id "$AWS_SECRET_ID" --secret "$AWS_SECRET_KEY"
$ cbctl create region region-aws-tokyo --csp aws --region ap-northeast-1 --zone ap-northeast-1a 
$ cbctl create connection config-aws-tokyo --csp aws --region region-aws-tokyo --credential credential-aws
$ cbctl create namespace acornsoft
```

```
$ cbctl delete image config-aws-tokyo-ubuntu1804

$ cbctl create cluster \
  --name "cb-cluster"\
  --control-plane-connection="config-aws-tokyo"\
  --control-plane-count="1"\
  --control-plane-spec="t3.medium"\
  --worker-connection="config-aws-tokyo"\
  --worker-count="1"\
  --worker-spec="t3.medium"

$ cbctl create cluster \
  --name "cb-cluster"\
  --control-plane-connection="config-aws-tokyo"\
  --control-plane-count="3"\
  --control-plane-spec="t3.medium"\
  --worker-connection="config-aws-tokyo"\
  --worker-count="5"\
  --worker-spec="t3.medium"



$ cbctl create cluster \
  --name "cb-cluster"\
  --control-plane-connection="config-aws-tokyo"\
  --control-plane-count="3"\
  --control-plane-spec="t3.medium"\
  --worker-connection="config-aws-tokyo"\
  --worker-count="27"\
  --worker-spec="t3.medium"

$ cbctl create cluster \
  --name "cb-cluster"\
  --control-plane-connection="config-aws-tokyo"\
  --control-plane-count="3"\
  --control-plane-spec="t2.medium"\
  --worker-connection="config-aws-tokyo"\
  --worker-count="47"\
  --worker-spec="t2.medium"
```

```
$ cbctl update-kubeconfig cb-cluster
```

## TB

* AWS에서 아래와 같이 InsufficientInstanceCapacity 오류가 나기도함
```
InsufficientInstanceCapacity:
  We currently do not have sufficient t2.medium capacity in the Availability Zone
  you requested (ap-northeast-1a). Our system will be working on provisioning additional
  capacity. You can currently get t2.medium capacity by not specifying an Availability
  Zone in your request or choosing ap-northeast-1c, ap-northeast-1d.
```

## docker environment

```
#!/bin/bash
docker run -d --rm -p 1024:1024 --name cb-spider -v "$(pwd)/data/spider:/data" -e CBSTORE_ROOT=/data cloudbaristaorg/cb-spider:0.6.8
docker run -d --rm -p 1323:1323 --name cb-tumblebug --link cb-spider:cb-spider -v "$(pwd)/data/tumblebug/conf:/app/conf" -v "$(pwd)/data/tumblebug/meta_db:/app/meta_db/dat" -v "$(pwd)/data/tumblebug/log:/app/log" cloudbaristaorg/cb-tumblebug:0.6.3
# docker run -d --rm -p 1470:1470 --name cb-mcks --link cb-spider:cb-spider --link cb-tumblebug:cb-tumblebug -v "$(pwd)/data/mcks:/data" -e SPIDER_URL=http://cb-spider:1024/spider -e TUMBLEBUG_URL=http://cb-tumblebug:1323/tumblebug -e CBSTORE_ROOT=/data cloudbaristaorg/cb-mcks:0.6.1
docker run -d --rm -p 1470:1470 --name cb-mcks --link cb-spider:cb-spider --link cb-tumblebug:cb-tumblebug -v "$(pwd)/data/mcks:/data" -e SPIDER_URL=http://cb-spider:1024/spider -e TUMBLEBUG_URL=http://cb-tumblebug:1323/tumblebug -e CBSTORE_ROOT=/data honester/cb-mcks:latest
```

## Clean-up 

```
$ docker stop cb-mcks cb-tumblebug cb-spider
$ rm -rf data/mcks/meta_db/ data/spider/meta_db/ data/tumblebug/meta_db/
$ rm -f kubeconfig/* output/* ssh/*
```

## 임시

```
$ chmod 400 ssh/cb-cluster.pem
$ ssh -i ssh/cb-cluster.pem ubuntu@18.182.7.230
```

./bootstrap2.sh 1.23.12-00 aws cb-cluster 18.181.185.66 canal

