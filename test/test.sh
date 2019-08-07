#!/bin/bash

#shellcheck disable=SC2016

DIR="$( cd "$(dirname "$0")" || exit ; pwd -P )"
DOCKER_COMPOSE="docker-compose.yml"
CONTROLLER="controller"
DATABASE="database"
WORKER01="worker01"
WORKER02="worker02"
CONTAINERS="$CONTROLLER $DATABASE $WORKER01 $WORKER02"

drun() {
  docker exec -it "$1" "${@:2}"
}

cleanup() {
  rm -rf "${DIR}/../home" "${DIR}/../secret"
  docker-compose -f "${DIR}/../${DOCKER_COMPOSE}" down
}

setup() {
  cleanup
  docker-compose -f "${DIR}/../${DOCKER_COMPOSE}" up -d

  # check cluster status
  local s=1
  for _ in $(seq 1 3); do
    docker logs "$CONTROLLER" 2>/dev/null | grep "Adding Cluster(s)" && s=0 && break || s=$? && sleep 3
  done
  return "$(exit $s)"
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
  drun "$CONTROLLER" sinfo || return 1
}

check_slurm_srun() {
  drun "$CONTROLLER" srun -N 2 hostname || return 1
}

check_slurm_sbatch() {
  drun "$CONTROLLER" bash -c '
SBATCH_FILE="/tmp/slurm_test.job"
cat <<EOF > "$SBATCH_FILE"
#!/bin/bash

#SBATCH --job-name=SLURM_TEST
#SBATCH --output=SLURM_TEST.out
#SBATCH --error=SLURM_TEST.err
#SBATCH --partition=docker

srun hostname | sort
EOF

sbatch -N 2 $SBATCH_FILE
' || return 1

  drun "$CONTROLLER" squeue || return 1

}

check_slurm_sbatch_array() {
  drun "$CONTROLLER" bash -c '
SBATCH_FILE="/tmp/array_test.job"
cat <<EOF > "$SBATCH_FILE"
#!/bin/bash

#SBATCH -N 1
#SBATCH -c 1
#SBATCH -t 24:00:00
###################
## %A == SLURM_ARRAY_JOB_ID
## %a == SLURM_ARRAY_TASK_ID (or index)
## %N == SLURMD_NODENAME (directories made ahead of time)
#SBATCH -o /tmp/%N/%A_%a_out.txt
#SBATCH -e /tmp/%N/%A_%a_err.txt

snooze=$(( ( RANDOM % 10 )  + 1 ))
echo "$(hostname) is snoozing for ${snooze} seconds..."

sleep $snooze
EOF

mkdir -p /tmp/worker01 /tmp/worker02
sinfo -N
sbatch --array=1-20%2 "$SBATCH_FILE"
' || return 1

  drun "$CONTROLLER" squeue || return 1

}

setup
check_slurm_status
check_slurm_sinfo
check_slurm_srun
check_slurm_sbatch
check_slurm_sbatch_array
teardown
