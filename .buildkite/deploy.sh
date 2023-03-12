#!/bin/bash

set -euo pipefail

buildkite-agent artifact download terraform/terraform .
chmod +x terraform/terraform
mv terraform/terraform infrastructure/

cd infrastructure
./terraform init
