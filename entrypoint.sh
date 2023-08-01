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
cd apptainer-in-docker
docker build -t hotwa/input:apptainer -f Dockerfile .
cd ..

# Convert Docker image
docker run --name sifbuild -v /var/run/docker.sock:/var/run/docker.sock -v $(pwd):/work hotwa/input:apptainer build /work/${INPUT_DOCKERFILE_PATH}-${TIMESTAMP}.sif docker-daemon://hotwa/input:latest

# Sign Docker image if Apptainer key is set
if [ -n "$APPTAINER_KEY" ]; then
    # Stop and remove the sifbuild container
    docker rm -f sifbuild
    docker run --name sifsign -v ~/.apptainer:/root/.apptainer -v $(pwd):/work hotwa/input:apptainer sign /work/${INPUT_DOCKERFILE_PATH}-${TIMESTAMP}.sif
    # Copy the sif file from the sifsign container
    docker cp sifsign:/work/${INPUT_DOCKERFILE_PATH}-${TIMESTAMP}.sif $(pwd)
    # Remove the sifsign container
    docker rm -f sifsign
else
    # Copy the sif file from the sifbuild container
    docker cp sifbuild:/work/${INPUT_DOCKERFILE_PATH}-${TIMESTAMP}.sif $(pwd)
    # Remove the sifbuild container
    docker rm -f sifbuild
fi

# Package SIF file
tar czvf ${INPUT_DOCKERFILE_PATH}-${TIMESTAMP}.sif.tar.gz ${INPUT_DOCKERFILE_PATH}-${TIMESTAMP}.sif

