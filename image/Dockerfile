ARG TERRARIA_VERSION="1449"

FROM ubuntu:focal as base
RUN apt update && apt install -y curl unzip

FROM base as terraria
ARG TERRARIA_VERSION
RUN curl --fail --show-error --silent "https://www.terraria.org/api/download/pc-dedicated-server/terraria-server-${TERRARIA_VERSION}.zip" > terraria.zip && \
    unzip -q terraria && \
    chmod +x ${TERRARIA_VERSION}/Linux/TerrariaServer.bin.x86_64

FROM base as tailscale
RUN curl --fail --location --show-error --silent "https://pkgs.tailscale.com/stable/tailscale_latest_amd64.tgz" > tailscale.tar.gz && \
    tar -xf tailscale.tar.gz --strip-components=1

FROM base as awscli
RUN curl --fail --show-error --silent "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" > awscliv2.zip && \
    unzip -q awscliv2.zip && \
    ./aws/install --bin-dir "/aws-cli-bin/"

FROM ubuntu:focal
ARG TERRARIA_VERSION
RUN apt update && \
    apt install -y iproute2 jq screen && \
    mkdir -p /terrarium
COPY --from=terraria ./${TERRARIA_VERSION}/Linux/ /terrarium/terraria/
COPY --from=tailscale ./tailscale ./tailscaled /usr/local/bin/
COPY --from=awscli /usr/local/aws-cli/ /usr/local/aws-cli/
COPY --from=awscli /aws-cli-bin/ /usr/local/bin/
WORKDIR /terrarium
ADD entrypoint.sh ./
CMD /bin/bash entrypoint.sh
