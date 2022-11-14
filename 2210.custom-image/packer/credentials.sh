for ARGUMENT in "$@"
do

    KEY=$(echo $ARGUMENT | cut -f1 -d=)
    VALUE=$(echo $ARGUMENT | cut -f2 -d=)   

    case "$KEY" in
            aws)        AWS_FILE=${VALUE} ;;
            gcp)        GCP_FILE=${VALUE} ;;
            azure)      AZURE_FILE=${VALUE} ;;
            alibaba)    ALIBABA_FILE=${VALUE} ;;
            tencent)    TENCENT_FILE=${VALUE} ;;
            openstack)  OPENSTACK_FILE=${VALUE} ;;
            ibm)        IBM_FILE=${VALUE} ;;
            cloudit)    CLOUDIT_FILE=${VALUE} ;;
            *)   
    esac    


done
if [ "${AWS_FILE}" != "" ]; then 
	#FILE="${HOME}/.aws/credentials"
	export AWS_SECRET_ID="$(head -n 3 ${AWS_FILE} | tail -n 1 | sed  '/^$/d; s/\r//; s/aws_access_key_id = //g')"
	export AWS_SECRET_KEY="$(head -n 2 ${AWS_FILE} | tail -n 1 | sed  '/^$/d; s/\r//; s/aws_secret_access_key = //g')"
	echo "export AWS_SECRET_ID=\"${AWS_SECRET_ID}\""
	echo "export AWS_SECRET_KEY=\"${AWS_SECRET_KEY}\""
else
	echo "$KEY IS NOT SUPPORTED"
fi

