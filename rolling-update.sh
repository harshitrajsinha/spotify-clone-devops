#!/bin/bash

# IMAGE="frontend-image:v1"            # "backend-image:v1"
# SERVICE="frontend"                   # "backend"
# NETWORK="traefik-net"
# EXPOSED_PORT="81"                    # "8000"
# PRIORITY="1"                         # "10"
# ROUTE_PATH="/"                       # "/api"                     

IMAGE="$1"
SERVICE="$2"
NETWORK="$3"
EXPOSED_PORT="$4"
PRIORITY="$5"
ROUTE_PATH="$6"

echo "Pulling latest image..."
docker pull $IMAGE

OLD_CONTAINERS=$(docker ps \
    --filter "label=com.docker.compose.service=$SERVICE" \
    --format "{{.Names}}")

for OLD in $OLD_CONTAINERS
do
    NEW="${OLD}-new"

    echo "Starting replacement for $OLD"

    docker run -d \
        --name $NEW \
        --network $NETWORK \
        --expose $EXPOSED_PORT \
        --label "traefik.enable=true" \
        --label "traefik.http.routers.${SERVICE}.rule=PathPrefix(\"${ROUTE_PATH}\")" \
        --label "traefik.http.services.${SERVICE}.loadbalancer.server.port=${EXPOSED_PORT}" \
        --label "traefik.http.routers.${SERVICE}.priority=${PRIORITY}" \
        --label "com.docker.compose.service=${SERVICE}" \
        $IMAGE

    echo "Waiting for health..."

    until [ "$(docker inspect \
        --format='{{.State.Health.Status}}' \
        $NEW)" = "healthy" ]
    do
        sleep 2
    done

    echo "Stopping old container"

    docker stop "$OLD"
    docker rm "$OLD"

    docker rename "$NEW" "$OLD"

done