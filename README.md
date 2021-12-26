# terrarium

A little Terraria server on demand.

```sh
docker build --tag terrarium image
docker run --rm --publish 7777:7777 \
    --mount "type=bind,src=$PWD/terraria.cfg,dst=/home/terrarium/terraria.cfg,readonly" \
    terrarium
```
