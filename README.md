# terrarium

A little on-demand Terraria server. It runs on AWS Fargate and accepts connection from my [Tailscale](https://tailscale.com/) tailnet.

```sh
# Deploy infra
make infra

# Start server (using test.cfg as config)
./start.sh config/test.cfg

# Connect to the server console
make console
```
