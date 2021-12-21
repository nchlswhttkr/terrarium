FROM ubuntu:focal as download
ARG TERRARIA_VERSION
RUN apt update && apt install -y curl unzip
RUN curl https://www.terraria.org/api/download/pc-dedicated-server/terraria-server-${TERRARIA_VERSION}.zip > terraria.zip
RUN unzip terraria
RUN chmod +x ${TERRARIA_VERSION}/Linux/TerrariaServer.bin.x86_64

FROM ubuntu:focal
ARG TERRARIA_VERSION
RUN apt update && \
    apt install -y screen iproute2 && \
    useradd -m -s /bin/bash terrarium && \
    mkdir -p /home/terrarium/terraria && \
    chown -R terrarium:terrarium /home/terrarium/terraria
COPY --from=download ./${TERRARIA_VERSION}/Linux/ /home/terrarium/terraria/
USER terrarium
WORKDIR /home/terrarium
ADD entrypoint.sh ./
CMD /bin/bash entrypoint.sh
