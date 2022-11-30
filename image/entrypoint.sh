#!/bin/bash

set -euo pipefail

function shut_down_server() {
    screen -S terraria -X stuff "exit\n"
    while screen -list | grep "terraria" > /dev/null; do sleep 1; done
    tailscale logout
    exit 0
}

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
# Shut down after 180 x 5s = ~15mins if nobody connects
CONNECTION_ATTEMPTS=0
until has_active_connections; do
    if [[ $CONNECTION_ATTEMPTS -gt 180 ]]; then
        echo "No players connected to server, giving up and shutting down..."
        shut_down_server
    fi
    sleep 5;
    CONNECTION_ATTEMPTS=$((CONNECTION_ATTEMPTS + 1))
done

echo "Server is up and running!"
while has_active_connections; do sleep 60; done

echo "All players disconnected, shutting down..."
shut_down_server
