# terrarium

Terraria server on demand.

```sh
docker build -t terrarium --build-arg TERRARIA_VERSION=1432 .
docker run --rm --mount "type=bind,src=$PWD/terraria.cfg,dst=/home/terrarium/terraria.cfg,readonly" -p 7777:7777 terrarium
```
