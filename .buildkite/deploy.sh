#!/bin/bash

set -euo pipefail

cd infrastructure
terraform init
terraform apply -auto-approve
