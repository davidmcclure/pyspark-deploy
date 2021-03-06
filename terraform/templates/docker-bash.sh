#!/bin/bash

CONTAINER_ID=$(sudo docker ps -q --filter "name=spark")
DOCKER_CMD="sudo docker exec -it ${CONTAINER_ID} bash"

tmux attach -t spark || tmux new -s spark "$DOCKER_CMD"
