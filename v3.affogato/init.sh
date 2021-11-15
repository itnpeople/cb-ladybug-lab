#!/bin/bash
# ------------------------------------------------------------------------------
source ./env.sh
source ./credential.sh

if [ "${c_REGION}" == "" ]; then echo "Variable 'c_REGION' is mandatory"; exit 0; fi
if [ "${c_ZONE}" == "" ]; then echo "Variable 'c_ZONE' is mandatory"; exit 0; fi


NM_DRIVER="${CSP}-driver-v1.0"
NM_REGION="region-${CSP}-${R}"
NM_CREDENTIAL="credential-${CSP}-${R}"


# ------------------------------------------------------------------------------
# 드라이버 등록
curl -sX DELETE -H "${c_CT}" ${c_URL_SPIDER}/driver/${CSP}-driver-v1.0
curl -sX POST   -H "${c_CT}" ${c_URL_SPIDER}/driver -d @- <<EOF
{
"DriverName"        : "${NM_DRIVER}",
"ProviderName"      : "${CSP_UPPER}",
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
	"ProviderName"     : "${CSP_UPPER}", 
	"KeyValueInfoList" : [
		{"Key" : "Region", "Value" : "${c_REGION}"},
		{"Key" : "Zone",   "Value" : "${c_ZONE}"}]
	}
EOF

else

	curl -sX POST   -H "${c_CT}" ${c_URL_SPIDER}/region -d @- <<EOF
	{
	"RegionName"       : "${NM_REGION}",
	"ProviderName"     : "${CSP_UPPER}", 
	"KeyValueInfoList" : [
		{"Key" : "location", 		"Value" : "${c_REGION}"},
		{"Key" : "ResourceGroup",   "Value" : "${c_AZURE_RESOURCE_GROUP}"}]
	}
EOF

fi




# ------------------------------------------------------------------------------
# credential 환경변수

if [ "${CSP}" == "gcp" ]; then
	d="{
		\"CredentialName\"   : \"${NM_CREDENTIAL}\",
		\"ProviderName\"     : \"${CSP_UPPER}\",
		\"KeyValueInfoList\" : [
			{\"Key\" : \"ClientEmail\", \"Value\" : \"${c_GCP_SA}\"},
			{\"Key\" : \"ProjectID\",   \"Value\" : \"${c_GCP_PROJECT}\"},
			{\"Key\" : \"PrivateKey\",  \"Value\" : \"${c_GCP_PKEY}\"}
		]
	}"
elif [ "${CSP}" == "azure" ]; then
	d="{
		\"CredentialName\"   : \"${NM_CREDENTIAL}\",
		\"ProviderName\"     : \"${CSP_UPPER}\",
		\"KeyValueInfoList\" : [
			{\"Key\" : \"ClientId\",        \"Value\" : \"${c_AZURE_CLIENT_ID}\"},
			{\"Key\" : \"ClientSecret\",    \"Value\" : \"${c_AZURE_CLIENT_SECRET}\"},
			{\"Key\" : \"TenantId\",        \"Value\" : \"${c_AZURE_TENANT_ID}\"},
			{\"Key\" : \"SubscriptionId\",  \"Value\" : \"${c_AZURE_SUBSCRIPTION_ID}\"}
		]
	}"
elif [ "${CSP}" == "openstack" ]; then
	d="{
		\"CredentialName\"   : \"${NM_CREDENTIAL}\",
		\"ProviderName\"     : \"${CSP_UPPER}\",
		\"KeyValueInfoList\" : [
			{\"Key\" : \"IdentityEndpoint\",  \"Value\" : \"${OS_AUTH_URL}\"},
			{\"Key\" : \"Username\",          \"Value\" : \"${OS_USERNAME}\"},
			{\"Key\" : \"Password\",          \"Value\" : \"${OS_PASSWORD}\"},
			{\"Key\" : \"DomainName\",        \"Value\" : \"${OS_USER_DOMAIN_NAME}\"},
			{\"Key\" : \"ProjectID\",         \"Value\" : \"${OS_PROJECT_ID}\"}
		]
	}"
else
	# aws, alibaba, tencent
	d="{
		\"CredentialName\"   : \"${NM_CREDENTIAL}\",
		\"ProviderName\"     : \"${CSP_UPPER}\",
		\"KeyValueInfoList\" : [
			{\"Key\" : \"ClientId\",       \"Value\" : \"${c_SECRET_ID}\"},
			{\"Key\" : \"ClientSecret\",   \"Value\" : \"${c_SECRET_KEY}\"}
		]
	}"
fi
curl -sX DELETE -H "${c_CT}" ${c_URL_SPIDER}/credential/${NM_CREDENTIAL}
curl -sX POST   -H "${c_CT}" ${c_URL_SPIDER}/credential                  -d "${d}"

# ------------------------------------------------------------------------------
# Conn. info 등록
curl -sX DELETE -H "${c_CT}" -H "${c_AUTH}" ${c_URL_SPIDER}/connectionconfig/${c_CONFIG}
curl -sX POST   -H "${c_CT}" -H "${c_AUTH}" ${c_URL_SPIDER}/connectionconfig -d @- <<EOF
{
	"ConfigName"     : "${c_CONFIG}",
	"ProviderName"   : "${CSP_UPPER}", 
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
	"description" : "${CSP_UPPER}"
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
echo "CONNECTION INFO. : ${c_CONFIG}"
echo "NAMESPACE        : ${c_NS}"
