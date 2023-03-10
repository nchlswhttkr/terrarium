#!/bin/bash

set -euo pipefail

# Ensure server is reachable before attempting SSH
ping -c1 -W1 terrarium >/dev/null

ssh -t -o StrictHostKeyChecking=no root@terrarium screen -d -r -S terraria
