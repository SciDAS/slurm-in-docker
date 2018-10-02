#!/bin/bash

#Purpose: Generate a framework for a slurm-in-docker SciApp of N containers.

#Command line arguments
# $1 - SciApp name
NAME=$1
# $2 - # of workers
NUMW=$2
# $3 - # of vCPUs per worker
CPUS=$3
# $4 - Memory per worker(Mb)
MEM=$4
# $5 - Disk per worker(Mb)
DISK=$5
# $6 - GFS Server list - ex. "129.114.109.172:glusterfs 129.114.109.181:gluster-w0"
SERVERS=$6

#Generate lists of worker hostnames
for i in $(seq 1 $2); do 
WORKERS=( "${WORKERS[@]}" "worker$i" );
AWORKERS=( "${AWORKERS[@]}" "@worker$i" );
done

#Generate beginning of framework
cat > ./$NAME.json <<EOF
{
  "id": "$NAME",
  "containers": [
    {
      "id": "controller",
      "type": "service",
      "resources":
      {
        "cpus": 1,
        "mem": 4096,
        "disk": 8192
      },
      "network_mode": "container",
      "image": "cbmckni/slurm-sciapp-ctld:gfs",
      "is_privileged": true,
      "ports":[
        {
          "host_port": 20022,
          "container_port": 22,
          "protocol": "tcp"
        }
      ],
      "env":
      {
        "NODE_NAME": "@controller controller",
        "USE_SLURMDBD": "true",
        "CLUSTER_NAME": "snowflake",
        "CONTROL_MACHINE":"@controller",
        "SLURMCTLD_PORT": "6817",
        "SLURMD_PORT": "6818",
        "ACCOUNTING_STORAGE_HOST": "@db",
        "ACCOUNTING_STORAGE_PORT": "6819",
        "COMPUTE_NODES": "${AWORKERS[@]}",
        "PARTITION_NAME": "docker",
        "EXTRA_HOSTS": "$SERVERS",
        "GFS_SERVERS": "glusterfs",
        "GFS_SERVER_DIRS": "/gv0/home:/gv0/.secret:/gv0/modules:/gv0/modulefiles",
        "GFS_CLIENT_DIRS": "/home:/.secret:/opt/apps/Linux:/opt/apps/modulefiles/Linux",
        "MEM": "$MEM",
        "CPUS": "$CPUS"
      },
      "force_pull_image": true
    },
    {
      "id": "db",
      "dependencies": [
        "controller"
      ],
      "type": "service",
      "resources":
      {
        "cpus": 1,
        "mem": 4096,
        "disk": 4096
      },
      "network_mode": "container",
      "image": "cbmckni/slurm-sciapp-db:gfs",
      "is_privileged": true,
      "env":
      {
        "NODE_NAME": "@db db",
        "DBD_ADDR": "@db",
        "DBD_HOST": "localhost",
        "DBD_PORT": "6819",
        "STORAGE_HOST": "@db",
        "STORAGE_PORT": "3306",
        "STORAGE_PASS": "password",
        "STORAGE_USER": "slurm",
        "EXTRA_HOSTS": "$SERVERS",
        "GFS_SERVERS": "glusterfs",
        "GFS_SERVER_DIRS": "/gv0/home:/gv0/.secret:/gv0/modules:/gv0/modulefiles",
        "GFS_CLIENT_DIRS": "/home:/.secret:/opt/apps/Linux:/opt/apps/modulefiles/Linux"
      },
      "force_pull_image": true
    },
EOF

#Add framework of n containers to end of file
for i in $(seq 1 $2); do
cat >> ./$NAME.json <<EOF
    {
      "id": "worker$i",
      "dependencies": [
        "db"
      ],
      "type": "service",
      "resources":
      {
        "cpus": $CPUS,
        "mem": $MEM,
        "disk": $DISK
      },
      "network_mode": "container",
      "image": "cbmckni/slurm-sciapp-worker:gfs",
      "is_privileged": true,
      "env":
      {
        "NODE_NAME": "${AWORKERS[$i-1]} ${WORKERS[$i-1]}",
        "CONTROL_MACHINE":"@controller",
        "ACCOUNTING_STORAGE_HOST": "@db",
        "COMPUTE_NODES": "${AWORKERS[@]}",
        "EXTRA_HOSTS": "$SERVERS",
        "GFS_SERVERS": "glusterfs",
        "GFS_SERVER_DIRS": "/gv0/home:/gv0/.secret:/gv0/modules:/gv0/modulefiles",
        "GFS_CLIENT_DIRS": "/home:/.secret:/opt/apps/Linux:/opt/apps/modulefiles/Linux"
      },
      "force_pull_image": true
    },
EOF
done 

#Remove last comma
truncate -s-2 ./$NAME.json

#End framework
echo "" >> ./$NAME.json
echo "  ]" >> ./$NAME.json
echo "}" >> ./$NAME.json



#User confirms generated framework is correct
echo "Generated Mesos framework: $NAME.json"
cat ./$NAME.json
