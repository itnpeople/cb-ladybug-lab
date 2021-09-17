#!/bin/bash
# ------------------------------------------------------------------------------

if [ "$1" != "" ]; then CSP="$1"; fi
if [ "$2" != "" ]; then R="$2"; fi
if [ "$3" != "" ]; then FILE="$3"; fi
if [ "${CSP}" == "" ]; then echo "Variable 'CSP' is mandatory"; exit -1; fi
if [ "${R}" == "" ]; then echo "Variable 'R'(region) is mandatory"; exit -1; fi
if [ "${FILE}" == "" ]; then echo "Variable 'FILE'(credential filepath) is mandatory"; exit -1; fi

# ------------------------------------------------------------------------------
if [ "${CSP}" == "aws" ]; then 
	#FILE="${HOME}/.aws/credentials"
	export c_SECRET_ID="$(head -n 3 ${FILE} | tail -n 1 | sed  '/^$/d; s/\r//; s/aws_access_key_id = //g')"
	export c_SECRET_KEY="$(head -n 2 ${FILE} | tail -n 1 | sed  '/^$/d; s/\r//; s/aws_secret_access_key = //g')"
fi
if [ "${CSP}" == "gcp" ]; then 
	#FILE="${HOME}/.ssh/google-credential-cloudbarista.json"
	export c_GCP_PROJECT=$(cat ${FILE} | jq ".project_id" | tr -d '"')
	export c_GCP_PKEY=$(cat ${FILE} | jq ".private_key" | tr -d '"')
	export c_GCP_SA=$(cat ${FILE} | jq ".client_email" | tr -d '"')
fi
if [ "${CSP}" == "azure" ]; then 
	#FILE="${HOME}/.azure/azure-credential-cloudbarista.json"
	export c_AZURE_SUBSCRIPTION_ID="$(cat ${FILE} | jq '.subscriptionId' | sed  '/^$/d; s/\r//; s/"//g')"
	export c_AZURE_TENANT_ID="$(cat ${FILE} | jq '.tenantId' | sed  '/^$/d; s/\r//; s/"//g')"
	export c_AZURE_CLIENT_ID="$(cat ${FILE} | jq '.clientId' | sed  '/^$/d; s/\r//; s/"//g')"
	export c_AZURE_CLIENT_SECRET="$(cat ${FILE} | jq '.clientSecret' | sed  '/^$/d; s/\r//; s/"//g')"
fi
if [ "${CSP}" == "tencent" ]; then 
	#FILE="${HOME}/.tccli/default.credential"
	export c_SECRET_ID="$(cat ${FILE} | jq '.secretId' | sed  '/^$/d; s/\r//; s/"//g')"
	export c_SECRET_KEY="$(cat ${FILE} | jq '.secretKey' | sed  '/^$/d; s/\r//; s/"//g')"
fi


