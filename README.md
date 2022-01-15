# terrarium

A little Terraria server on demand.

```sh
docker build --tag terrarium image
docker run --rm --publish 7777:7777 \
    --mount "type=bind,src=$PWD/infrastructure/terraria.cfg,dst=/terrarium/terraria.cfg,readonly" \
    --mount "type=bind,src=$PWD/worlds,dst=/terrarium/worlds" \
    terrarium
```
