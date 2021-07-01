#!/bin/bash
c_NS="acornsoft"
c_AZURE_RESOURCE_GROUP="cb-ladybugRG"
c_URL_SPIDER="http://localhost:1024/spider"
c_URL_TUMBLEBUG="http://localhost:1323/tumblebug"
c_CT="Content-Type: application/json"
c_AUTH="Authorization: Basic $(echo -n default:default | base64)"

# ------------------------------------------------------------------------------
if [ "$1" != "" ]; then CSP="$1"; fi
if [ "$2" != "" ]; then R="$2"; fi
if [ "$3" != "" ]; then v_FILE="$3"; fi
if [ "${CSP}" == "" ]; then echo "Variable 'CSP' empty"; exit 0; fi
if [ "${R}" == "" ]; then echo "Variable 'R' empty"; exit 0; fi
if [ "${v_FILE}" == "" ]; then echo "Variable 'credential filepath' empty"; exit 0; fi

c_CSP_UPPER="$(echo ${CSP} | tr [:lower:] [:upper:])"
NM_DRIVER="${CSP}-driver-v1.0"
NM_REGION="region-${CSP}-${R}"
NM_CREDENTIAL="credential-${CSP}-${R}"
NM_CONFIG="config-${CSP}-${R}"

if [ "${CSP}" == "aws" ]; then 
	if [ "${R}" == "seoul" ];		then c_REGION="ap-northeast-2";	c_ZONE="ap-northeast-2a"; fi
	if [ "${R}" == "tokyo" ];		then c_REGION="ap-northeast-1";	c_ZONE="ap-northeast-1a"; fi
	if [ "${R}" == "singapore" ];	then c_REGION="ap-southeast-1";	c_ZONE="ap-southeast-1a"; fi
	if [ "${R}" == "usca" ];		then c_REGION="us-west-1";		c_ZONE="us-west-1b"; fi
	if [ "${R}" == "london" ];		then c_REGION="eu-west-2";		c_ZONE="eu-west-2a"; fi
	if [ "${R}" == "india" ];		then c_REGION="ap-south-1";		c_ZONE="ap-south-1a"; fi
fi
if [ "${CSP}" == "gcp" ]; then 
	if [ "${R}" == "seoul" ];		then c_REGION="asia-northeast3";	c_ZONE="asia-northeast3-a"; fi
	if [ "${R}" == "tokyo" ];		then c_REGION="asia-northeast1";	c_ZONE="asia-northeast1-a"; fi
	if [ "${R}" == "singapore" ];	then c_REGION="asia-southeast1";	c_ZONE="asia-southeast1-a"; fi
	if [ "${R}" == "usca" ];		then c_REGION="us-west2";			c_ZONE="us-west2-a"; fi
	if [ "${R}" == "london" ];		then c_REGION="europe-west2";		c_ZONE="europe-west2-a"; fi
fi
if [ "${CSP}" == "azure" ]; then 
	if [ "${R}" == "seoul" ];		then c_REGION="koreacentral";	c_ZONE="*"; fi
	if [ "${R}" == "tokyo" ];		then c_REGION="japaneast";		c_ZONE="*"; fi
	if [ "${R}" == "singapore" ];	then c_REGION="southeastasia";	c_ZONE="*"; fi
	if [ "${R}" == "usca" ];		then c_REGION="westus";			c_ZONE="*"; fi
	if [ "${R}" == "london" ];		then c_REGION="uksouth";		c_ZONE="*"; fi
fi


if [ "${c_REGION}" == "" ]; then echo "Variable 'c_REGION' empty"; exit 0; fi
if [ "${c_ZONE}" == "" ]; then echo "Variable 'c_ZONE' empty"; exit 0; fi


# ------------------------------------------------------------------------------
# 드라이버 등록
curl -sX DELETE -H "${c_CT}" ${c_URL_SPIDER}/driver/${CSP}-driver-v1.0
curl -sX POST   -H "${c_CT}" ${c_URL_SPIDER}/driver -d @- <<EOF
{
"DriverName"        : "${NM_DRIVER}",
"ProviderName"      : "${c_CSP_UPPER}",
"DriverLibFileName" : "${NM_DRIVER}.so"
}
EOF

# ------------------------------------------------------------------------------
# 리전 등록 #1
curl -sX DELETE -H "${c_CT}" ${c_URL_SPIDER}/region/region-${CSP}-${R}

if [ "${CSP}" != "azure" ]; then 

	curl -sX POST   -H "${c_CT}" ${c_URL_SPIDER}/region -d @- <<EOF
	{
	"RegionName"       : "${NM_REGION}",
	"ProviderName"     : "${c_CSP_UPPER}", 
	"KeyValueInfoList" : [
		{"Key" : "Region", "Value" : "${c_REGION}"},
		{"Key" : "Zone",   "Value" : "${c_ZONE}"}]
	}
EOF

else

	curl -sX POST   -H "${c_CT}" ${c_URL_SPIDER}/region -d @- <<EOF
	{
	"RegionName"       : "${NM_REGION}",
	"ProviderName"     : "${c_CSP_UPPER}", 
	"KeyValueInfoList" : [
		{"Key" : "location", 		"Value" : "${c_REGION}"},
		{"Key" : "ResourceGroup",   "Value" : "${c_AZURE_RESOURCE_GROUP}"}]
	}
EOF

fi




# ------------------------------------------------------------------------------
# credential 환경변수
source ./credential.sh "${CSP}" "${R}" "${v_FILE}"

# Credential 등록 #AWS
curl -sX DELETE -H "${c_CT}" ${c_URL_SPIDER}/credential/${NM_CREDENTIAL}

if [ "${CSP}" == "aws" ]; then 

curl -sX POST   -H "${c_CT}" ${c_URL_SPIDER}/credential -d @- <<EOF
{
"CredentialName"   : "${NM_CREDENTIAL}",
"ProviderName"     : "${c_CSP_UPPER}",
"KeyValueInfoList" : [
	{"Key" : "ClientId",       "Value" : "${c_AWS_KEY}"},
	{"Key" : "ClientSecret",   "Value" : "${c_AWS_SECRET}"}
]}
EOF

fi

# Credential 등록 #GCP
if [ "${CSP}" == "gcp" ]; then 

curl -sX POST   -H "${c_CT}" ${c_URL_SPIDER}/credential -d @- <<EOF
{
"CredentialName"   : "${NM_CREDENTIAL}",
"ProviderName"     : "${c_CSP_UPPER}",
"KeyValueInfoList" : [
	{"Key" : "ClientEmail", "Value" : "${c_GCP_SA}"},
	{"Key" : "ProjectID",   "Value" : "${c_GCP_PROJECT}"},
	{"Key" : "PrivateKey",  "Value" : "${c_GCP_KEY}"}
]}
EOF

fi

# Credential 등록 #AZURE
if [ "${CSP}" == "azure" ]; then 

curl -sX POST   -H "${c_CT}" ${c_URL_SPIDER}/credential -d @- <<EOF
{
"CredentialName"   : "${NM_CREDENTIAL}",
"ProviderName"     : "${c_CSP_UPPER}",
"KeyValueInfoList" : [
	{"Key" : "SubscriptionId",	"Value" : "${c_AZURE_SUBSCRIPTION_ID}"},
	{"Key" : "TenantId",   		"Value" : "${c_AZURE_TENANT_ID}"},
	{"Key" : "ClientId",		"Value" : "${c_AZURE_CLIENT_ID}"},
	{"Key" : "ClientSecret",	"Value" : "${c_AZURE_CLIENT_SECRET}"}
]}
EOF

fi

# ------------------------------------------------------------------------------
# Conn. info 등록
curl -sX DELETE -H "${c_CT}" -H "${c_AUTH}" ${c_URL_SPIDER}/connectionconfig/${NM_CONFIG}
curl -sX POST   -H "${c_CT}" -H "${c_AUTH}" ${c_URL_SPIDER}/connectionconfig -d @- <<EOF
{
	"ConfigName"     : "${NM_CONFIG}",
	"ProviderName"   : "${c_CSP_UPPER}", 
	"DriverName"     : "${CSP}-driver-v1.0", 
	"CredentialName" : "${NM_CREDENTIAL}", 
	"RegionName"     : "${NM_REGION}"
}
EOF


# ------------------------------------------------------------------------------
# 네임스페이스 (공통)
#curl -sX DELETE -H "${c_AUTH}" -H "${c_CT}" ${c_URL_TUMBLEBUG}/ns/${c_NS}
curl -sX POST   -H "${c_AUTH}" -H "${c_CT}" ${c_URL_TUMBLEBUG}/ns -d @- <<EOF
{
	"name"        : "${c_NS}",
	"description" : "${c_CSP_UPPER}"
}
EOF



# ------------------------------------------------------------------------------
# 결과확인
echo "# ------------------------------------------------------------------------------"
curl -sX GET ${c_URL_SPIDER}/driver           -H "${c_CT}" | jq > ./output/driver.json
curl -sX GET ${c_URL_SPIDER}/region           -H "${c_CT}" | jq > ./output/region.json
curl -sX GET ${c_URL_SPIDER}/credential       -H "${c_CT}" | jq > ./output/credential.json
curl -sX GET ${c_URL_SPIDER}/connectionconfig -H "${c_CT}" | jq > ./output/connectionconfig.json
curl -sX GET ${c_URL_TUMBLEBUG}/ns            -H "${c_AUTH}" -H "${c_CT}" | jq > ./output/ns.json
echo "DRIVER           : ${NM_DRIVER}"
echo "REGION           : ${NM_REGION}"
echo "CREDENTIAL       : ${NM_CREDENTIAL}"
echo "CONNECTION INFO. : ${NM_CONFIG}"
echo "NAMESPACE        : ${c_NS}"
