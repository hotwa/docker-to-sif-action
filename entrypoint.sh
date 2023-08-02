#!/bin/bash
set -e
export TZ=Asia/Shanghai
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
INPUT_DOCKERFILE_PATH=$DOCKERFILE_PATH
ALIYUN_IMAGE=$ALIYUN_IMAGE
ALIYUN_USERNAME=$ALIYUN_USERNAME
ALIYUN_PASSWORD=$ALIYUN_PASSWORD
APPTAINER_KEY=$APPTAINER_KEY

# Check if ALIYUN_IMAGE variable is set. If so, log in to Aliyun and pull the image.
if [ -n "$ALIYUN_IMAGE" ]; then
    echo "Aliyun image provided. Logging in to Aliyun and pulling the image..."
    echo "$ALIYUN_PASSWORD" | docker login --username $ALIYUN_USERNAME --password-stdin registry.cn-hangzhou.aliyuncs.com
    docker pull $ALIYUN_IMAGE
    IMAGE_NAME=$ALIYUN_IMAGE
# If ALIYUN_IMAGE is not set, check if INPUT_DOCKERFILE_PATH variable is set. If so, build the Docker image.
elif [ -n "$INPUT_DOCKERFILE_PATH" ]; then
    echo "Dockerfile path provided. Building Docker image..."
    docker build -t hotwa/input:latest -f ${INPUT_DOCKERFILE_PATH} .
    IMAGE_NAME=hotwa/input:latest
else
    echo "Error: Neither ALIYUN_IMAGE nor INPUT_DOCKERFILE_PATH was provided."
    exit 1
fi

# Replace '/' and ':' in IMAGE_NAME with '_', and append TIMESTAMP to create a valid file name.
SIF_FILE_NAME=$(echo "${IMAGE_NAME}-${TIMESTAMP}" | tr '/:' '__')

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
docker run --name sifbuild -v /var/run/docker.sock:/var/run/docker.sock -v $(pwd):/work hotwa/input:apptainer build /work/${SIF_FILE_NAME}.sif docker-daemon://${IMAGE_NAME}

# Sign Docker image if Apptainer key is set
if [ -n "$APPTAINER_KEY" ]; then
    # Stop and remove the sifbuild container
    docker rm -f sifbuild
    docker run --name sifsign -v ~/.apptainer:/root/.apptainer -v $(pwd):/work hotwa/input:apptainer sign /work/${SIF_FILE_NAME}.sif
    # Copy the sif file from the sifsign container
    docker cp sifsign:/work/${SIF_FILE_NAME}.sif $(pwd)
    # Remove the sifsign container
    docker rm -f sifsign
else
    # Copy the sif file from the sifbuild container
    docker cp sifbuild:/work/${SIF_FILE_NAME}.sif $(pwd)
    # Remove the sifbuild container
    docker rm -f sifbuild
fi

# Package SIF file
tar czvf apptainer.sif.tar.gz ${SIF_FILE_NAME}.sif

echo "current dir file:"
ls
