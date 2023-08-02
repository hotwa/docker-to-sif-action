FROM debian:buster-slim

COPY entrypoint.sh /entrypoint.sh

RUN apt-get update && \
    apt-get install -y git tree docker.io && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
