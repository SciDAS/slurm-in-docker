#!/bin/bash

DIR="$( cd "$(dirname "$0")" || exit ; pwd -P )"
DOCKER_COMPOSE="docker-compose.yml"
CONTROLLER="controller"
DATABASE="database"
WORKER01="worker01"
WORKER02="worker02"
CONTAINERS="$CONTROLLER $DATABASE $WORKER01 $WORKER02"

cleanup() {
  rm -rf "${DIR}/../home" "${DIR}/../secret"
  docker-compose -f "${DIR}/../${DOCKER_COMPOSE}" down
}

setup() {
  cleanup
  docker-compose -f "${DIR}/../${DOCKER_COMPOSE}" up -d
}

teardown() {
  cleanup
}

check_slurm_status() {
  for c in $CONTAINERS; do
    [ "$(docker inspect -f '{{.State.Running}}' "$c")" = true ] || return 1
  done
}

check_slurm_sinfo() {
  docker exec -it "$CONTROLLER" sinfo || return 1
}

check_slurm_srun() {
  docker exec -it "$CONTROLLER" srun -N 2 hostname || return 1
}

setup
check_slurm_status
check_slurm_sinfo
check_slurm_srun
teardown
