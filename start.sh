#!/bin/bash

set -euo pipefail

export AWS_REGION="ap-southeast-2"
AWS_ACCESS_KEY_ID=$(pass show website/aws-access-key-id)
export AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY=$(pass show website/aws-access-key-secret)
export AWS_SECRET_ACCESS_KEY
CLOUDFLARE_API_TOKEN=$(pass show website/cloudflare-api-token)
CLOUDFLARE_ZONE_ID=$(pass show website/cloudflare-zone-id)

CLUSTER_ARN=$(terraform -chdir=infrastructure output "ecs_cluster_arn" | jq -r)
VPC_SUBNET_ID=$(terraform -chdir=infrastructure output "vpc_subnet_id" | jq -r)
TASK_DEFINITION_ARN=$(terraform -chdir=infrastructure output "task_definition_arn" | jq -r)
CONFIG_S3_BUCKET=$(terraform -chdir=infrastructure output "config_s3_bucket" | jq -r)

aws s3 sync config/ "s3://${CONFIG_S3_BUCKET}/"

TASK_ARN=$(
    aws ecs run-task \
        --cluster "${CLUSTER_ARN}" \
        --count 1 \
        --launch-type "FARGATE" \
        --network-configuration "
            {
                \"awsvpcConfiguration\": {
                    \"subnets\": [\"${VPC_SUBNET_ID}\"],
                    \"assignPublicIp\": \"ENABLED\"
                }
            }
        " \
        --task-definition "${TASK_DEFINITION_ARN}" \
        | jq -r ".tasks[0].taskArn"
)

curl --silent --fail "https://api.cloudflare.com/client/v4/zones/${CLOUDFLARE_ZONE_ID}/dns_records?name=terraria.nicholas.cloud&type=A" \
    -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
    -H "Content-Type: application/json" \
    | jq -r ".result[].id" \
    | while read -r RECORD_ID; do
        curl --silent --fail -X DELETE "https://api.cloudflare.com/client/v4/zones/${CLOUDFLARE_ZONE_ID}/dns_records/${RECORD_ID}" \
            -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
            -H "Content-Type: application/json" > /dev/null
done

sleep 5 # give ENI a moment to provision
ENI_ID=$(
    aws ecs describe-tasks --cluster "${CLUSTER_ARN}" --tasks "${TASK_ARN}" \
        | jq -r ".tasks[0].attachments[0].details[] | select(.name == \"networkInterfaceId\") | .value"
)

PUBLIC_IP=$(
    aws ec2 describe-network-interfaces --network-interface-ids "${ENI_ID}" \
        | jq -r ".NetworkInterfaces[0].Association.PublicIp"
)

curl --silent --fail -X POST "https://api.cloudflare.com/client/v4/zones/${CLOUDFLARE_ZONE_ID}/dns_records" \
    -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
    -H "Content-Type: application/json" \
    --data "
        {
            \"type\": \"A\",
            \"name\": \"terraria.nicholas.cloud\",
            \"content\": \"${PUBLIC_IP}\",
            \"ttl\": 1,
            \"proxied\": false
        }
    " > /dev/null
echo "terraria.nicholas.cloud now pointing to ${PUBLIC_IP}"


