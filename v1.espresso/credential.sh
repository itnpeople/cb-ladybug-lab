#!/bin/bash
v_FILE="/Users/eunsang/.ssh/google-credential-cloudbarista.json"
export c_GCP_PROJECT=$(cat ${v_FILE} | jq -r ".project_id")
export c_GCP_KEY=$(cat ${v_FILE} | jq -r ".private_key" | while read line; do	if [[ "$line" != "" ]]; then	echo -n "$line\n";	fi; done )
export c_GCP_SA=$(cat ${v_FILE} | jq -r ".client_email")

v_FILE="/Users/eunsang/.aws/credentials"
export c_AWS_KEY="$(head -n 3 ${v_FILE} | tail -n 1 | sed  '/^$/d; s/\r//; s/aws_access_key_id = //g')"
export c_AWS_SECRET="$(head -n 2 ${v_FILE} | tail -n 1 | sed  '/^$/d; s/\r//; s/aws_secret_access_key = //g')"
