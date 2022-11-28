#!/bin/bash

# $1 - The name of the config file to load, for example

set -euo pipefail

export AWS_REGION="ap-southeast-2"
AWS_ACCESS_KEY_ID=$(pass show website/aws-access-key-id)
export AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY=$(pass show website/aws-access-key-secret)
export AWS_SECRET_ACCESS_KEY

CLUSTER_ARN=$(terraform -chdir=infrastructure output "ecs_cluster_arn" | jq -r)
VPC_SUBNET_ID=$(terraform -chdir=infrastructure output "vpc_subnet_id" | jq -r)
TASK_DEFINITION_ARN=$(terraform -chdir=infrastructure output "task_definition_arn" | jq -r)
CONFIG_S3_BUCKET=$(terraform -chdir=infrastructure output "config_s3_bucket" | jq -r)

if ! [[ -a "${1}" ]] || ! [[ "${1}" =~ ^config/[[:alnum:]-]+.cfg$ ]]; then
    echo "Config file ${1} does not exist or has an invalid name"
    exit 1
fi
CONFIG_NAME="${1#config/}"
echo "Starting terraria.nicholas.cloud with config ${CONFIG_NAME}"

echo "Syncing config files to S3"
aws s3 sync config/ "s3://${CONFIG_S3_BUCKET}/config/"

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
        --overrides "
            {
                \"containerOverrides\": [
                    {
                        \"name\": \"server\",
                        \"environment\": [
                            {
                                \"name\": \"CONFIG_NAME\",
                                \"value\": \"${CONFIG_NAME}\"
                            }
                        ]
                    }
                ]
            }
        " \
        --task-definition "${TASK_DEFINITION_ARN}" \
        | jq -r ".tasks[0].taskArn"
)

echo "Inspect task at https://${AWS_REGION}.console.aws.amazon.com/ecs/home#/clusters/terrarium/tasks/${TASK_ARN##*/}/details"