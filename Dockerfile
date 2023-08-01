FROM debian:buster-slim

RUN apt-get update && \
    apt-get install -y git docker.io

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
