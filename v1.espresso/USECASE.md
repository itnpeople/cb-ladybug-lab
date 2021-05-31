# USECASE

## Tumblebug

### ssh-key 생성 & 조회
* 생성 시 cloud object가 생성되지는 않음

```
c_URL_TUMBLEBUG="http://localhost:1323/tumblebug"
c_NS="cb-${CSP}-namespace"
c_CT="Content-Type: application/json"
c_AUTH="Authorization: Basic $(echo -n default:default | base64)"
c_URL_TUMBLEBUG_NS="${c_URL_TUMBLEBUG}/ns/${c_NS}"
c_CONFIG="cb-${CSP}-config"


(curl -sX POST ${c_URL_TUMBLEBUG_NS}/resources/sshKey   -H "${c_AUTH}" -H "${c_CT}"  -d @- <<EOF
{
  "connectionName": "${c_CONFIG}",
  "description": "",
  "name": "cb-${CSP}-${R}-sshkey"
}
EOF
) | jq

curl -sX GET ${c_URL_TUMBLEBUG_NS}/resources/sshKey/cb-${CSP}-${R}-sshkey   -H "${c_AUTH}" -H "${c_CT}" -d "{"connectionName" : \"${c_CONFIG}\"}" | jq
```

### vpc 생성 & 조회
* 생성 시 cloud object가 생성되지는 않음

```
c_URL_TUMBLEBUG="http://localhost:1323/tumblebug"
c_NS="cb-${CSP}-namespace"
c_CT="Content-Type: application/json"
c_AUTH="Authorization: Basic $(echo -n default:default | base64)"
c_URL_TUMBLEBUG_NS="${c_URL_TUMBLEBUG}/ns/${c_NS}"
c_CONFIG="cb-${CSP}-config"

(curl -sX POST ${c_URL_TUMBLEBUG_NS}/resources/vNet   -H "${c_AUTH}" -H "${c_CT}"  -d @- <<EOF
{
  "cidrBlock": "192.168.0.0/16",
  "connectionName": "${c_CONFIG}",
  "description": "string",
  "name": "cb-${CSP}-${R}-vpc",
  "subnetInfoList": [
    {
      "ipv4_CIDR": "192.168.1.0/24",
      "keyValueList": [],
      "name": "cb-${CSP}-${R}-subnet"
    }
  ]
}
EOF
) | jq


curl -sX GET ${c_URL_TUMBLEBUG_NS}/resources/vNet/cb-${CSP}-${R}-vpc   -H "${c_AUTH}" -H "${c_CT}" -d "{"connectionName" : \"${c_CONFIG}\"}" | jq

```