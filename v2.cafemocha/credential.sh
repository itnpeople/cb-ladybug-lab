#!/bin/bash
if [ "$1" != "" ]; then CSP="$1"; fi
if [ "$2" != "" ]; then R="$2"; fi
if [ "$3" != "" ]; then v_FILE="$3"; fi
if [ "${CSP}" == "" ]; then echo "Variable 'CSP' empty"; exit 0; fi
if [ "${R}" == "" ]; then echo "Variable 'R' empty"; exit 0; fi
if [ "${v_FILE}" == "" ]; then echo "Variable 'credential filepath' empty"; exit 0; fi


if [ "${CSP}" == "aws" ]; then 
	#v_FILE="${HOME}/.aws/credentials"
	export c_AWS_KEY="$(head -n 3 ${v_FILE} | tail -n 1 | sed  '/^$/d; s/\r//; s/aws_access_key_id = //g')"
	export c_AWS_SECRET="$(head -n 2 ${v_FILE} | tail -n 1 | sed  '/^$/d; s/\r//; s/aws_secret_access_key = //g')"
fi
if [ "${CSP}" == "gcp" ]; then 
	#v_FILE="${HOME}/.ssh/google-credential-cloudbarista.json"
	export c_GCP_PROJECT=$(cat ${v_FILE} | jq -r ".project_id")
	export c_GCP_KEY=$(cat ${v_FILE} | jq -r ".private_key" | while read line; do	if [[ "$line" != "" ]]; then	echo -n "$line\n";	fi; done )
	export c_GCP_SA=$(cat ${v_FILE} | jq -r ".client_email")
fi
if [ "${CSP}" == "azure" ]; then 
	#v_FILE="${HOME}/.azure/azure-credential-cloudbarista.json"
	export c_AZURE_SUBSCRIPTION_ID="$(cat ${v_FILE} | jq '.subscriptionId' | sed  '/^$/d; s/\r//; s/"//g')"
	export c_AZURE_TENANT_ID="$(cat ${v_FILE} | jq '.tenantId' | sed  '/^$/d; s/\r//; s/"//g')"
	export c_AZURE_CLIENT_ID="$(cat ${v_FILE} | jq '.clientId' | sed  '/^$/d; s/\r//; s/"//g')"
	export c_AZURE_CLIENT_SECRET="$(cat ${v_FILE} | jq '.clientSecret' | sed  '/^$/d; s/\r//; s/"//g')"
fi


