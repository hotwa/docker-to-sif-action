#!/bin/bash
set -e

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
INPUT_DOCKERFILE_PATH=$1
APPTAINER_KEY=$2

# Build Docker image
docker build -t hotwa/input:latest -f ${INPUT_DOCKERFILE_PATH} .

# Write Apptainer key if it's set
if [ -n "$APPTAINER_KEY" ]; then
    mkdir -p ~/.apptainer/keys && echo "${APPTAINER_KEY}" | base64 -d > ~/.apptainer/keys/pgp-secret
fi

# Build apptainer image from kaczmarj/apptainer-in-docker Dockerfile
git clone https://github.com/kaczmarj/apptainer-in-docker
docker build -t hotwa/input:apptainer -f Dockerfile apptainer-in-docker/

# Convert Docker image
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v $(pwd):/work hotwa/input:apptainer build ${INPUT_DOCKERFILE_PATH}-${TIMESTAMP}.sif docker-daemon://hotwa/input:latest

# Sign Docker image if Apptainer key is set
if [ -n "$APPTAINER_KEY" ]; then
    docker run --rm -v ~/.apptainer:/root/.apptainer -v $(pwd):/work hotwa/input:apptainer sign /work/${INPUT_DOCKERFILE_PATH}-${TIMESTAMP}.sif
fi

# Package SIF file
tar czvf ${INPUT_DOCKERFILE_PATH}-${TIMESTAMP}.sif.tar.gz ${INPUT_DOCKERFILE_PATH}-${TIMESTAMP}.sif
