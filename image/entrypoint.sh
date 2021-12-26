#!/bin/bash

set -eo pipefail

function get_player_count() {
    screen -S terraria -X log on
    screen -S terraria -X stuff "playing\n"
    screen -S terraria -X log off
    tail -n 2 screenlog.* | head -n -1
    rm screenlog.*
}

echo "Starting Terraria server..."
screen -dm -S terraria terraria/TerrariaServer.bin.x86_64 -config /home/terrarium/terraria.cfg
until ss -lt | grep 0.0.0.0:7777 > /dev/null; do sleep 1; done

echo "Waiting for players to connect..."
while get_player_count | grep "No players connected" > /dev/null; do sleep 1; done
until get_player_count | grep "No players connected" > /dev/null; do get_player_count; sleep 60; done

echo "All players disconnected, shutting down..."
screen -S terraria -X stuff "exit\n"
until screen -list | grep "terraria" > /dev/null; do sleep 1; done
