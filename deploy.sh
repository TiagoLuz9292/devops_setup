#!/bin/bash

APP_NAME=$1
DOCKERHUB_REPO=$2
TAG=$3
SERVICE=$4
CONFIG_FILE=$5

if [ -z "$APP_NAME" ] || [ -z "$DOCKERHUB_REPO" ] || [ -z "$TAG" ] || [ -z "$SERVICE" ] || [ -z "$CONFIG_FILE" ]; then
    echo "Usage: $0 <app_name> <dockerhub_repo> <tag> <service> <config_file>"
    exit 1
fi

PORT=$(jq -r ".$SERVICE.port" $CONFIG_FILE)

if [ -z "$PORT" ]; then
    echo "Service $SERVICE not found in config file"
    exit 1
fi

echo "Deploying $APP_NAME-$SERVICE using image $DOCKERHUB_REPO-$SERVICE:$TAG on port $PORT"

docker pull $DOCKERHUB_REPO-$SERVICE:$TAG

if [ $? -ne 0 ]; then
    echo "Failed to pull the Docker image"
    exit 1
fi

# Stop and remove the container if it exists
docker stop ${APP_NAME}-$SERVICE || echo "No existing container to stop"
docker rm ${APP_NAME}-$SERVICE || echo "No existing container to remove"

docker run -d --name ${APP_NAME}-$SERVICE -p $PORT:$PORT $DOCKERHUB_REPO-$SERVICE:$TAG

if [ $? -eq 0 ]; then
    echo "$APP_NAME-$SERVICE deployed successfully!"
else
    echo "Failed to deploy $APP_NAME-$SERVICE"
    exit 1
fi