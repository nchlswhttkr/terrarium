#!/bin/bash

set -euo pipefail

function has_active_connections() {
    if [[ "$(tailscale status --json --active | jq ".Peer | keys | length")" == 0 ]]; then
        return 1
    fi
}

TAILSCALE_AUTHENTICATION_KEY=$(aws ssm get-parameter --with-decryption --name "/terrarium/tailscale-authentication-key" | jq --raw-output ".Parameter.Value")
tailscaled --tun=userspace-networking & # must be backgrounded
tailscale up --ssh --authkey "${TAILSCALE_AUTHENTICATION_KEY}" --hostname "terrarium"

echo "Fetcing server config ${CONFIG_NAME}"
mkdir -p ~/.aws
echo "
    [default]
    credential_source=EcsContainer
" > ~/.aws/config
aws s3 cp "s3://${CONFIG_S3_BUCKET}/config/${CONFIG_NAME}" terraria.cfg

echo "Starting Terraria server..."
screen -dm -S terraria terraria/TerrariaServer.bin.x86_64 -config /terrarium/terraria.cfg
until ss -lt | grep 0.0.0.0:7777 > /dev/null; do sleep 1; done

echo "Waiting for players to connect..."
# set timeout for startup
until has_active_connections; do sleep 5; done

echo "Server is up and running!"
while has_active_connections; do sleep 60; done

echo "All players disconnected, shutting down..."
screen -S terraria -X stuff "exit\n"
while screen -list | grep "terraria" > /dev/null; do sleep 1; done
