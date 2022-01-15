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

if [ ! -f terraria.cfg ]; then
    echo "Could not locate server config, fetching..."
    mkdir -p ~/.aws
    echo "
        [default]
        credential_source=EcsContainer
    " > ~/.aws/config
    aws s3 cp "s3://${CONFIG_S3_BUCKET}/test.cfg" terraria.cfg # TODO: Add logic to grab by variable file name
fi

echo "Starting Terraria server..."
screen -dm -S terraria terraria/TerrariaServer.bin.x86_64 -config /terrarium/terraria.cfg
until ss -lt | grep 0.0.0.0:7777 > /dev/null; do sleep 1; done

echo "Waiting for players to connect..."
while get_player_count | grep "No players connected" > /dev/null; do sleep 5; done
until get_player_count | grep "No players connected" > /dev/null; do get_player_count; sleep 60; done

echo "All players disconnected, shutting down..."
screen -S terraria -X stuff "exit\n"
while screen -list | grep "terraria" > /dev/null; do sleep 1; done
