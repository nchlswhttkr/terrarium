# terrarium [![Build status](https://badge.buildkite.com/a18bc8285a423d8e2a5f2a2fba524c55fc9c5c4b26b6e9e25f.svg?branch=main)](https://buildkite.com/nchlswhttkr/terrarium)

A little on-demand Terraria server. It runs on AWS Fargate and accepts connection from my [Tailscale](https://tailscale.com/) tailnet.

```sh
# Deploy infra
make -C infrastructure

# Start server (using test.cfg as config)
./start.sh config/test.cfg

# Connect to the server console
./console.sh
```
