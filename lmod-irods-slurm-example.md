# Lmod / iRODS Slurm Example

This example is based on the 4-node cluster deploy as described in [https://github.com/scidas/slurm-in-docker](https://github.com/scidas/slurm-in-docker).

## Setup

Prior to moving forward the user should have a running 4-node cluster deployed as described in [Slurm in Docker](https://github.com/scidas/slurm-in-docker).

Additionally the user should have the [irods-commands](https://github.com/scidas/lmod-modules-centos/tree/master/irods-icommands) Lmod packages deployed as described in [Lmod module packages for CentOS 7](https://github.com/scidas/lmod-modules-centos)

## Test

Get onto the `controller` node as the `worker` user and ensure you are in the `/home/worker` directory.

```console
$ docker exec -ti -u worker controller /bin/bash
[worker@controller /]$ cd /home/worker/
[worker@controller ~]$ pwd
/home/worker
```

Initialize the iRODS environment you want your workflow to use. This can be done with two files that use environment variables to set the iRODS user information on the system.

In this example we'll use public read-only credentials from the National Water Model (NWM) iRODS data archive. An additional iRODS setting will be used here named `"irods_home"`. This is not necessary, but useful for setting a default starting point within the Zone.

Create file `$HOME/irods.env`:

```bash
#!/usr/bin/env bash

export IRODS_HOST=nwm.renci.org
export IRODS_PORT=1247
export IRODS_USER_NAME=nwm-reader
export IRODS_ZONE_NAME=nwmZone
export IRODS_AUTHENTICATION=nwmreader
export IRODS_HOME=/nwmZone/home/nwm/data
```

Create file `$HOME/setup-irods-user-native.sh`

```bash
#!/usr/bin/env bash

source $HOME/irods.env

if [ ! -d $HOME/.irods/ ]; then
    mkdir -p $HOME/.irods/
    cat > $HOME/.irods/irods_environment.json <<EOF
{
    "irods_host": "${IRODS_HOST}",
    "irods_port": ${IRODS_PORT},
    "irods_user_name": "${IRODS_USER_NAME}",
    "irods_zone_name": "${IRODS_ZONE_NAME}",
    "irods_home": "${IRODS_HOME}"
}
EOF
fi

iinit $IRODS_AUTHENTICATION
```

These scripts will set iRODS related environment variables and then use them to create the iRODS files necessary for iCommands to use.

Prior to running the scripts there is likely no `$HOME/.irods/` directory, and the script will create this and populate it with the necessary information for iCommands usage.

Because the `/home` directory is a shared volume between all containers, the iRODS environment file will be generated for all nodes to make use of.

### controller node

Validate that icommands works from the controller node

```console
$ module load irods-icommands/4.1.11
$ module list

Currently Loaded Modules:
  1) irods-icommands/4.1.11



$ ./setup-irods-user-native.sh
$ ils
/nwmZone/home/nwm/data:
  C- /nwmZone/home/nwm/data/analysis_assim
  C- /nwmZone/home/nwm/data/fe_analysis_assim
  C- /nwmZone/home/nwm/data/forcing_analysis_assim
  C- /nwmZone/home/nwm/data/forcing_medium_range
  C- /nwmZone/home/nwm/data/forcing_short_range
  C- /nwmZone/home/nwm/data/long_range
  C- /nwmZone/home/nwm/data/medium_range
  C- /nwmZone/home/nwm/data/nomads
  C- /nwmZone/home/nwm/data/short_range
  C- /nwmZone/home/nwm/data/usgs_timeslices
```

Check the contents of the `$HOME/.irods/` directory

```console
$ ls -alh .irods/
total 8.0K
drwxrwxr-x 2 worker worker  49 Apr 27 16:51 .
drwx------ 4 worker worker 152 Apr 27 16:51 ..
-rw------- 1 worker worker  17 Apr 27 16:51 .irodsA
-rw-rw-r-- 1 worker worker 177 Apr 27 16:51 irods_environment.json
$ cat .irods/irods_environment.json
{
    "irods_host": "nwm.renci.org",
    "irods_port": 1247,
    "irods_user_name": "nwm-reader",
    "irods_zone_name": "nwmZone",
    "irods_home": "/nwmZone/home/nwm/data"
}
$ cat .irods/.irodsA
.Zp(v"k(s(rftdz(
```

### worker nodes

Validate the icommands works from the worker nodes

Using passwordless ssh to `worker01`

```console
$ ssh worker01
Last login: Fri Apr 27 11:54:59 2018 from controller.slurm-in-docker_slurm
$ module load irods-icommands/4.1.11
$ ./setup-irods-user-native.sh
$ ils
/nwmZone/home/nwm/data:
  C- /nwmZone/home/nwm/data/analysis_assim
  C- /nwmZone/home/nwm/data/fe_analysis_assim
  C- /nwmZone/home/nwm/data/forcing_analysis_assim
  C- /nwmZone/home/nwm/data/forcing_medium_range
  C- /nwmZone/home/nwm/data/forcing_short_range
  C- /nwmZone/home/nwm/data/long_range
  C- /nwmZone/home/nwm/data/medium_range
  C- /nwmZone/home/nwm/data/nomads
  C- /nwmZone/home/nwm/data/short_range
  C- /nwmZone/home/nwm/data/usgs_timeslices
```

Repeat for `worker02`

## Run a multi-node job

With the iRODS environments tested on the nodes we can put together an example batch script that runs on all nodes using iCommands.

The core pieces of the script will need to contain the loading of the `irods-icommands/4.1.11` module, and the initial `iinit` of the environment.

Lets create two new files, a batch job description and the iRODS related script for it to run.

### controller node

Create file `irods_batch.job`

```bash
#!/bin/bash

#SBATCH -N 1
#SBATCH -c 1
#SBATCH -t 24:00:00
###################
## %A == SLURM_ARRAY_JOB_ID
## %a == SLURM_ARRAY_TASK_ID (or index)
## %N == NODE_NAME
#SBATCH -o %N_%A_%a_out.txt
#SBATCH -e %N_%A_%a_err.txt

### Load modules
module load irods-icommands/4.1.11

### Run code (request 2 CPU to run job)
srun -N 2 ./my-irods-script.sh
```

Create file `my-irods-script.sh`


```
#!/bin/bash

### iinit iRODS
source $HOME/irods.env
iinit $IRODS_AUTHENTICATION

### sleep some random time between 1-10 seconds
snooze=$(( ( RANDOM % 10 )  + 1 ))
sleep $snooze

### do some stuff
echo "$(hostname) is snoozing for ${snooze} seconds..."
ils
echo "Bye!"
```

Run the batch job with a request for 2 CPU worth of nodes to run the array of 5 jobs

```
sbatch -N 2 --array=1-5%1 irods_batch.job
```

Observe the various output from `squeue` and `sacct` as the batch job runs.

```console
$ sbatch -N 2 --array=1-5%1 irods_batch.job
Submitted batch job 2
$ sacct
       JobID    JobName  Partition    Account  AllocCPUS      State ExitCode
------------ ---------- ---------- ---------- ---------- ---------- --------
2_[1-5%1]    irods_bat+     docker                     2    PENDING      0:0
$ squeue
             JOBID PARTITION     NAME     USER ST       TIME  NODES NODELIST(REASON)
         2_[3-5%1]    docker irods_ba   worker PD       0:00      2 (JobArrayTaskLimit)
               2_2    docker irods_ba   worker  R       0:01      2 worker[01-02]
$ sacct
       JobID    JobName  Partition    Account  AllocCPUS      State ExitCode
------------ ---------- ---------- ---------- ---------- ---------- --------
2_[3-5%1]    irods_bat+     docker                     2    PENDING      0:0
2_1          irods_bat+     docker                     2  COMPLETED      0:0
2_1.batch         batch                                1  COMPLETED      0:0
2_1.0        my-irods-+                                2  COMPLETED      0:0
2_2          irods_bat+     docker                     2    RUNNING      0:0
2_2.0        my-irods-+                                2    RUNNING      0:0
$ squeue
             JOBID PARTITION     NAME     USER ST       TIME  NODES NODELIST(REASON)
         2_[4-5%1]    docker irods_ba   worker PD       0:00      2 (JobArrayTaskLimit)
               2_3    docker irods_ba   worker  R       0:01      2 worker[01-02]
$ sacct
       JobID    JobName  Partition    Account  AllocCPUS      State ExitCode
------------ ---------- ---------- ---------- ---------- ---------- --------
2_[4-5%1]    irods_bat+     docker                     2    PENDING      0:0
2_1          irods_bat+     docker                     2  COMPLETED      0:0
2_1.batch         batch                                1  COMPLETED      0:0
2_1.0        my-irods-+                                2  COMPLETED      0:0
2_2          irods_bat+     docker                     2  COMPLETED      0:0
2_2.batch         batch                                1  COMPLETED      0:0
2_2.0        my-irods-+                                2  COMPLETED      0:0
2_3          irods_bat+     docker                     2    RUNNING      0:0
2_3.0        my-irods-+                                2    RUNNING      0:0
$ squeue
             JOBID PARTITION     NAME     USER ST       TIME  NODES NODELIST(REASON)
         2_[4-5%1]    docker irods_ba   worker PD       0:00      2 (JobArrayTaskLimit)
               2_3    docker irods_ba   worker  R       0:07      2 worker[01-02]
$ sacct
       JobID    JobName  Partition    Account  AllocCPUS      State ExitCode
------------ ---------- ---------- ---------- ---------- ---------- --------
2_[4-5%1]    irods_bat+     docker                     2    PENDING      0:0
2_1          irods_bat+     docker                     2  COMPLETED      0:0
2_1.batch         batch                                1  COMPLETED      0:0
2_1.0        my-irods-+                                2  COMPLETED      0:0
2_2          irods_bat+     docker                     2  COMPLETED      0:0
2_2.batch         batch                                1  COMPLETED      0:0
2_2.0        my-irods-+                                2  COMPLETED      0:0
2_3          irods_bat+     docker                     2    RUNNING      0:0
2_3.0        my-irods-+                                2    RUNNING      0:0
$ squeue
             JOBID PARTITION     NAME     USER ST       TIME  NODES NODELIST(REASON)
           2_[5%1]    docker irods_ba   worker PD       0:00      2 (JobArrayTaskLimit)
               2_4    docker irods_ba   worker  R       0:02      2 worker[01-02]
$ sacct
       JobID    JobName  Partition    Account  AllocCPUS      State ExitCode
------------ ---------- ---------- ---------- ---------- ---------- --------
2_5          irods_bat+     docker                     2    RUNNING      0:0
2_5.0        my-irods-+                                2    RUNNING      0:0
2_1          irods_bat+     docker                     2  COMPLETED      0:0
2_1.batch         batch                                1  COMPLETED      0:0
2_1.0        my-irods-+                                2  COMPLETED      0:0
2_2          irods_bat+     docker                     2  COMPLETED      0:0
2_2.batch         batch                                1  COMPLETED      0:0
2_2.0        my-irods-+                                2  COMPLETED      0:0
2_3          irods_bat+     docker                     2  COMPLETED      0:0
2_3.batch         batch                                1  COMPLETED      0:0
2_3.0        my-irods-+                                2  COMPLETED      0:0
2_4          irods_bat+     docker                     2  COMPLETED      0:0
2_4.batch         batch                                1  COMPLETED      0:0
2_4.0        my-irods-+                                2  COMPLETED      0:0
$ squeue
             JOBID PARTITION     NAME     USER ST       TIME  NODES NODELIST(REASON)
               2_5    docker irods_ba   worker  R       0:06      2 worker[01-02]
$ sacct
       JobID    JobName  Partition    Account  AllocCPUS      State ExitCode
------------ ---------- ---------- ---------- ---------- ---------- --------
2_5          irods_bat+     docker                     2  COMPLETED      0:0
2_5.batch         batch                                1  COMPLETED      0:0
2_5.0        my-irods-+                                2  COMPLETED      0:0
2_1          irods_bat+     docker                     2  COMPLETED      0:0
2_1.batch         batch                                1  COMPLETED      0:0
2_1.0        my-irods-+                                2  COMPLETED      0:0
2_2          irods_bat+     docker                     2  COMPLETED      0:0
2_2.batch         batch                                1  COMPLETED      0:0
2_2.0        my-irods-+                                2  COMPLETED      0:0
2_3          irods_bat+     docker                     2  COMPLETED      0:0
2_3.batch         batch                                1  COMPLETED      0:0
2_3.0        my-irods-+                                2  COMPLETED      0:0
2_4          irods_bat+     docker                     2  COMPLETED      0:0
2_4.batch         batch                                1  COMPLETED      0:0
2_4.0        my-irods-+                                2  COMPLETED      0:0
$ squeue
             JOBID PARTITION     NAME     USER ST       TIME  NODES NODELIST(REASON)
```

Review the output files

```console
$ ls -l
total 36
-rw-rw-r-- 1 worker worker  220 Apr 27 16:37 irods.env
-rw-rw-r-- 1 worker worker  303 Apr 27 17:39 irods_batch.job
-rwxrwxr-x 1 worker worker  270 Apr 27 17:40 my-irods-script.sh
-rwxrwxr-x 1 worker worker  389 Apr 27 16:38 setup-irods-user-native.sh
-rw-rw-r-- 1 worker worker    0 Apr 27 17:41 worker01_2_1_err.txt
-rw-rw-r-- 1 worker worker 1026 Apr 27 17:41 worker01_2_1_out.txt
-rw-rw-r-- 1 worker worker    0 Apr 27 17:41 worker01_2_2_err.txt
-rw-rw-r-- 1 worker worker 1026 Apr 27 17:41 worker01_2_2_out.txt
-rw-rw-r-- 1 worker worker    0 Apr 27 17:41 worker01_2_3_err.txt
-rw-rw-r-- 1 worker worker 1027 Apr 27 17:42 worker01_2_3_out.txt
-rw-rw-r-- 1 worker worker    0 Apr 27 17:42 worker01_2_4_err.txt
-rw-rw-r-- 1 worker worker 1026 Apr 27 17:42 worker01_2_4_out.txt
-rw-rw-r-- 1 worker worker    0 Apr 27 17:42 worker01_2_5_err.txt
-rw-rw-r-- 1 worker worker 1026 Apr 27 17:42 worker01_2_5_out.txt
```

Check the contents of an output file

```console
$ cat worker01_2_3_out.txt
worker02.local.dev is snoozing for 2 seconds...
/nwmZone/home/nwm/data:
  C- /nwmZone/home/nwm/data/analysis_assim
  C- /nwmZone/home/nwm/data/fe_analysis_assim
  C- /nwmZone/home/nwm/data/forcing_analysis_assim
  C- /nwmZone/home/nwm/data/forcing_medium_range
  C- /nwmZone/home/nwm/data/forcing_short_range
  C- /nwmZone/home/nwm/data/long_range
  C- /nwmZone/home/nwm/data/medium_range
  C- /nwmZone/home/nwm/data/nomads
  C- /nwmZone/home/nwm/data/short_range
  C- /nwmZone/home/nwm/data/usgs_timeslices
Bye!
worker01.local.dev is snoozing for 10 seconds...
/nwmZone/home/nwm/data:
  C- /nwmZone/home/nwm/data/analysis_assim
  C- /nwmZone/home/nwm/data/fe_analysis_assim
  C- /nwmZone/home/nwm/data/forcing_analysis_assim
  C- /nwmZone/home/nwm/data/forcing_medium_range
  C- /nwmZone/home/nwm/data/forcing_short_range
  C- /nwmZone/home/nwm/data/long_range
  C- /nwmZone/home/nwm/data/medium_range
  C- /nwmZone/home/nwm/data/nomads
  C- /nwmZone/home/nwm/data/short_range
  C- /nwmZone/home/nwm/data/usgs_timeslices
Bye!
```
