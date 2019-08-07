#!/bin/bash

#shellcheck disable=SC2016

DIR="$( cd "$(dirname "$0")" || exit ; pwd -P )"
DOCKER_COMPOSE="docker-compose.yml"
CONTROLLER="controller"
DATABASE="database"
WORKER01="worker01"
WORKER02="worker02"
CONTAINERS="$CONTROLLER $DATABASE $WORKER01 $WORKER02"

if command -v tput &>/dev/null; then
  RED=$(tput setaf 1)
  GREEN=$(tput setaf 2)
  NORMAL=$(tput sgr0)
  BOLD=$(tput bold)
else
  RED=$(echo -en "\e[31m")
  GREEN=$(echo -en "\e[32m")
  NORMAL=$(echo -en "\e[00m")
  BOLD=$(echo -en "\e[01m")
fi

drun() {
  docker exec -t -u worker "$1" "${@:2}"
}

cleanup() {
  docker-compose -f "${DIR}/../${DOCKER_COMPOSE}" down
  rm -rf "${DIR}/../home" "${DIR}/../secret"
}

setup() {

  cleanup
  docker-compose -f "${DIR}/../${DOCKER_COMPOSE}" up -d

  local start

  start="$(date +"%s")"

  local diff=$(( $(date +"%s") - start ))
  local wait=30

  # check controller status
  while [ $diff -lt $wait  ]; do
    docker logs "$CONTROLLER" 2>/dev/null | grep "Adding Cluster(s)" && break
    diff=$(( $(date +"%s") - start  ))
  done

  [ $diff -lt $wait  ] || return 1
}

teardown() {
  cleanup
}

check_slurm_status() {
  for c in $CONTAINERS; do
    [ "$(docker inspect -f '{{.State.Running}}' "$c")" == "true" ] || return 1
  done
}

check_slurm_sinfo() {
  local start

  start="$(date +"%s")"

  local diff=$(( $(date +"%s") - start ))
  local wait=30

  # check all workers' status should be idle
  while [ $diff -lt $wait ]; do
    drun "$CONTROLLER" sinfo 2>&1 | grep "worker\[01-02\]" | grep "idle" && break
    diff=$(( $(date +"%s") - start  ))
  done

  echo $diff $wait
  [ $diff -lt $wait  ] || return 1
}

check_slurm_srun() {
  drun "$CONTROLLER" srun -N 2 hostname || return 1
}

check_slurm_sbatch() {
  drun "$CONTROLLER" bash -c '
SBATCH_FILE="/home/worker/slurm_test.job"
cat <<EOF > "$SBATCH_FILE"
#!/bin/bash

#SBATCH --job-name=SLURM_TEST
#SBATCH --output=SLURM_TEST.out
#SBATCH --error=SLURM_TEST.err
#SBATCH --partition=docker

srun hostname | sort
EOF

cd /home/worker
sbatch -N 2 $SBATCH_FILE
' || return 1

  drun "$CONTROLLER" squeue || return 1

}

check_slurm_sbatch_array() {
  drun "$CONTROLLER" bash -c '
SBATCH_FILE="/home/worker/array_test.job"
cat <<EOF > "$SBATCH_FILE"
#!/bin/bash

#SBATCH -N 1
#SBATCH -c 1
#SBATCH -t 24:00:00
###################
## %A == SLURM_ARRAY_JOB_ID
## %a == SLURM_ARRAY_TASK_ID (or index)
## %N == SLURMD_NODENAME (directories made ahead of time)
#SBATCH -o %N/%A_%a_out.txt
#SBATCH -e %N/%A_%a_err.txt

snooze=\$(( ( RANDOM % 10 )  + 1 ))
echo "\$(hostname) is snoozing for \${snooze} seconds..."

sleep \$snooze
EOF

sinfo -N
mkdir -p /home/worker/worker01 /home/worker/worker02
cd /home/worker
sbatch --array=1-20%2 "$SBATCH_FILE"
' || return 1

  drun "$CONTROLLER" squeue || return 1

}

check_slurm_mpi() {

  drun "$CONTROLLER" bash -c '
MPI_HELLO="/home/worker/mpi_hello.c"
cat <<EOF > "$MPI_HELLO"
#include <mpi.h>
#include <stdio.h>
#include <stdlib.h>
#define  MASTER 0

int main (int argc, char *argv[]) {
   int   numtasks, taskid, len;
   char hostname[MPI_MAX_PROCESSOR_NAME];

   MPI_Init(&argc, &argv);
   MPI_Comm_size(MPI_COMM_WORLD, &numtasks);
   MPI_Comm_rank(MPI_COMM_WORLD,&taskid);
   MPI_Get_processor_name(hostname, &len);

   printf ("Hello from task %d on %s!\n", taskid, hostname);

   if (taskid == MASTER)
      printf("MASTER: Number of MPI tasks is: %d\n",numtasks);

   MPI_Finalize();
   return 0;
}
EOF

cd /home/worker
mpicc mpi_hello.c -Wall -Wextra -O3 -pedantic -Wl,--as-needed -o mpi_hello.out
scp mpi_hello.out worker@worker01:/home/worker
scp mpi_hello.out worker@worker02:/home/worker

srun --mpi=openmpi mpi_hello.out
srun -N 2 --mpi=openmpi mpi_hello.out
srun -N 2 --mpi=pmi2 mpi_hello.out
' || return 1


  # test sbatch
  drun "$CONTROLLER" bash -c '
MPI_BATCH=/home/worker/mpi_batch.job
cat <<EOF > "$MPI_BATCH"
#!/bin/bash

#SBATCH -N 1
#SBATCH -c 1
#SBATCH -t 24:00:00
###################
## %A == SLURM_ARRAY_JOB_ID
## %a == SLURM_ARRAY_TASK_ID (or index)
#SBATCH -o mpi_out/%A_%a_out.txt
#SBATCH -e mpi_out/%A_%a_err.txt

snooze=\$(( ( RANDOM % 10 )  + 1 ))
sleep \$snooze

srun -N 2 --mpi=openmpi mpi_hello.out
EOF

mkdir -p /home/worker/mpi_out
cd /home/worker
sbatch -N 2 --array=1-5%1 $MPI_BATCH
' || return 1

  drun "$CONTROLLER" sacct || return 1

}

summary() {

  local tests=(
    check_slurm_status
    check_slurm_sinfo
    check_slurm_srun
    check_slurm_sbatch
    check_slurm_sbatch_array
    check_slurm_mpi
  )


  local rc=0
  local num=1

  echo "1..${#tests[@]}"

  # retry setup
  setup || return 1

  for t in "${tests[@]}"; do
    # run the test
    if $t ; then
      echo "${BOLD}${GREEN}ok${NORMAL} $num - $t"
    else
      rc=1
      echo "${BOLD}${RED}not ok${NORMAL} $num - $t"
    fi
  done

  teardown
  return $rc
}

summary
