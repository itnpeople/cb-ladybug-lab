#!/bin/bash
# ------------------------------------------------------------------------------
source ./const.env


# ------------------------------------------------------------------------------
# show init result
echo "DRIVER";     curl -sX GET ${c_URL_SPIDER}/driver				-H "${c_CT}" | jq;
echo "CREDENTIAL"; curl -sX GET ${c_URL_SPIDER}/credential			-H "${c_CT}" | jq;
echo "REGION";     curl -sX GET ${c_URL_SPIDER}/region				-H "${c_CT}" | jq;
echo "CONFIG";     curl -sX GET ${c_URL_SPIDER}/connectionconfig	-H "${c_CT}" | jq;

