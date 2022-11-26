#!/bin/bash

set -euo pipefail

function get_player_count() {
    screen -S terraria -X log on
    screen -S terraria -X stuff "playing\n"
    sleep 1
    screen -S terraria -X log off
    tail -n 2 screenlog.* | head -n -1
    rm screenlog.*
}

TAILSCALE_AUTHENTICATION_KEY=$(aws ssm get-parameter --with-decryption --name "/terrarium/tailscale-authentication-key" | jq --raw-output ".Parameter.Value")
tailscaled --tun=userspace-networking & # must be backgrounded
tailscale up --ssh --authkey "${TAILSCALE_AUTHENTICATION_KEY}"

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
while get_player_count | grep "No players connected" > /dev/null; do sleep 5; done
until get_player_count | grep "No players connected" > /dev/null; do get_player_count; sleep 60; done

echo "All players disconnected, shutting down..."
screen -S terraria -X stuff "exit\n"
while screen -list | grep "terraria" > /dev/null; do sleep 1; done
