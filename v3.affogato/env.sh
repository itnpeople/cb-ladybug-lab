#!/bin/bash
# ------------------------------------------------------------------------------
if [ "$1" != "" ]; then CSP="$1"; fi
if [ "$2" != "" ]; then R="$2"; fi
#if [ "${CSP}" == "" ]; then echo "Variable 'CSP' is mandatory"; exit -1; fi
#if [ "${R}" == "" ]; then echo "Variable 'R'(region) is mandatory"; exit -1; fi

# ------------------------------------------------------------------------------
source ./const.env

CSP_UPPER="$(echo ${CSP} | tr [:lower:] [:upper:])"

c_CONFIG="config-${CSP}-${R:=0}"
c_CLUSTER="${CLUSTER:=cb-cluster}"

if [ "${CSP}" == "aws" ]; then 
	if [ "${R}" == "seoul" ];		then c_REGION="ap-northeast-2";	fi
	if [ "${R}" == "tokyo" ];		then c_REGION="ap-northeast-1";	fi
	if [ "${R}" == "singapore" ];	then c_REGION="ap-southeast-1";	fi
	if [ "${R}" == "usca" ];		then c_REGION="us-west-1";		fi
	if [ "${R}" == "london" ];		then c_REGION="eu-west-2";		fi
	if [ "${R}" == "india" ];		then c_REGION="ap-south-1";		fi
	c_ZONE="${c_REGION}a"
	c_SPEC="t2.medium"
fi
if [ "${CSP}" == "gcp" ]; then 
	if [ "${R}" == "seoul" ];		then c_REGION="asia-northeast3";	fi
	if [ "${R}" == "tokyo" ];		then c_REGION="asia-northeast1";	fi
	if [ "${R}" == "singapore" ];	then c_REGION="asia-southeast1";	fi
	if [ "${R}" == "usca" ];		then c_REGION="us-west2";			fi
	if [ "${R}" == "london" ];		then c_REGION="europe-west2";		fi
	c_ZONE="${c_REGION}-a"
	c_SPEC="e2-highcpu-4"
fi
if [ "${CSP}" == "azure" ]; then 
	if [ "${R}" == "seoul" ];		then c_REGION="koreacentral";	fi
	if [ "${R}" == "tokyo" ];		then c_REGION="japaneast";		fi
	if [ "${R}" == "singapore" ];	then c_REGION="southeastasia";	fi
	if [ "${R}" == "usca" ];		then c_REGION="westus";			fi
	if [ "${R}" == "london" ];		then c_REGION="uksouth";		fi
	c_ZONE="*"
	c_SPEC="Standard_B2s"
	c_AZURE_RESOURCE_GROUP="${AZURE_RG:=cb-mcks}"
fi
if [ "${CSP}" == "alibaba" ]; then 
	#if [ "${R}" == "seoul" ];		then c_REGION="ap-seoul";			c_ZONE="${c_REGION}a";	c_SPEC="";	fi
	if [ "${R}" == "tokyo" ];		then c_REGION="ap-northeast-1";		c_ZONE="${c_REGION}a";	c_SPEC="ecs.t5-lc1m2.large";	fi	#2 vCPU, 4G
	if [ "${R}" == "singapore" ];	then c_REGION="ap-southeast-1";		c_ZONE="${c_REGION}a";	c_SPEC="ecs.t5-lc1m2.large";	fi
	if [ "${R}" == "usca" ];		then c_REGION="us-west-1";			c_ZONE="${c_REGION}a";	c_SPEC="ecs.t5-lc1m2.large";	fi
	if [ "${R}" == "london" ];		then c_REGION="eu-west-1";			c_ZONE="${c_REGION}a";	c_SPEC="ecs.t5-lc1m2.large";	fi
fi
if [ "${CSP}" == "tencent" ]; then 
	if [ "${R}" == "seoul" ];		then c_REGION="ap-seoul";			c_ZONE="${c_REGION}-2";	c_SPEC="S5.LARGE8";	fi	# Zone 1  "S5.LARGE8" 없음
	if [ "${R}" == "tokyo" ];		then c_REGION="ap-tokyo";			c_ZONE="${c_REGION}-2";	c_SPEC="S5.LARGE8";	fi	# Zone 1  "S5.LARGE8" 없음
	if [ "${R}" == "singapore" ];	then c_REGION="ap-singapore";		c_ZONE="${c_REGION}-1";	c_SPEC="S5.LARGE8"; fi
	if [ "${R}" == "usca" ];		then c_REGION="na-siliconvalley";	c_ZONE="${c_REGION}-2";	c_SPEC="S5.LARGE8"; fi
	if [ "${R}" == "london" ];		then c_REGION="eu-frankfurt";		c_ZONE="${c_REGION}-1";	c_SPEC="S5.LARGE8"; fi
fi
if [ "${CSP}" == "openstack" ]; then 
	c_REGION="${OS_REGION_NAME}"
	c_ZONE="${c_REGION}"
	c_SPEC="m1.medium";
fi