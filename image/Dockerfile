ARG TERRARIA_VERSION=1432

FROM ubuntu:focal as download
ARG TERRARIA_VERSION
RUN apt update && apt install -y curl unzip && \
    curl "https://www.terraria.org/api/download/pc-dedicated-server/terraria-server-${TERRARIA_VERSION}.zip" > terraria.zip && \
    unzip terraria && \
    chmod +x ${TERRARIA_VERSION}/Linux/TerrariaServer.bin.x86_64

FROM ubuntu:focal
ARG TERRARIA_VERSION
RUN apt update && \
    apt install -y screen iproute2 curl unzip && \
    mkdir -p /terrarium && \
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" > awscliv2.zip && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -rf awscliv2.zip aws/
COPY --from=download ./${TERRARIA_VERSION}/Linux/ /terrarium/terraria/
WORKDIR /terrarium
ADD entrypoint.sh ./
CMD /bin/bash entrypoint.sh
