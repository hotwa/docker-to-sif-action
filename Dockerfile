FROM debian:buster-slim

COPY entrypoint.sh /entrypoint.sh

RUN apt-get update && \
    apt-get install -y git docker.io && \
    chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
