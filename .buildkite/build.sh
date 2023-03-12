#!/bin/bash

set -euo pipefail

echo "--- Building Terrarium image"
docker build --tag terrarium ./image

echo "--- Checking Terrarium image"
# TODO: Record these versions as a label on the image
docker run --rm terrarium aws --version
docker run --rm terrarium tailscale --version

echo "--- Pushing Terrarium image"
docker tag terrarium "ghcr.io/nchlswhttkr/terrarium:$BUILDKITE_COMMIT"
docker tag terrarium "ghcr.io/nchlswhttkr/terrarium:$BUILDKITE_BRANCH"
GITHUB_ACCESS_TOKEN="$(vault kv get -mount=kv -field github_access_token buildkite/terrarium)"
echo "$GITHUB_ACCESS_TOKEN" | docker login ghcr.io --username nchlswhttkr --password-stdin
docker push --all-tags ghcr.io/nchlswhttkr/terrarium
docker logout ghcr.io
