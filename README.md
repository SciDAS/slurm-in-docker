# Slurm in Docker

**WORK IN PROGRESS**

Use [Docker](https://www.docker.com/) to explore the various components of [Slurm](https://www.schedmd.com/index.php)

This work represents a small exploratory Slurm cluster using CentOS 7 based Docker images. The intent was to learn the basics of Slurm prior to extending the concept to a more distributed environment.

## Contents

1. [packages](packages) - Build the RPM packages for running Slurm on CentOS 7
2. [base](base) - Slurm base image from which other components are based
3. [controller](controller) - Slurm controller (head-node) definition
4. [database](database) - Slurm database definition (not necessary, but useful for accounting information)
5. [worker](worker) - Slurm worker (compute-node) definition

## Container Overview

An example [docker-compose.yml](docker-compose.yml) file is provided that builds and deploys the diagramed topology

<img width="90%" alt="Slurm cluster" src="https://user-images.githubusercontent.com/5332509/38642211-67a7e1a4-3da7-11e8-85a9-3394ad3c8cb6.png">

Listing of participating containers with FQDNs and their function within the cluster.

Container | Function | FQDN
:-------- | :------- | :--- 
controller | Slurm Primary Controller | controller.local.dev
database | Slurm Primary Database Daemon | database.local.dev
worker01 | Slurm Worker | worker01.local.dev
worker02 | Slurm Worker | worker02.local.dev

## Build

Build the slurm RPM files by following the instructions in the [packages](packages) directory.

**Create the base Slurm image**:

Copy the `packages/centos-7/rpms` directory to the `base` directory

```
cd base/
cp -r ../packages/centos-7/rpms .
```

Build the base image

```
docker build -t mjstealey/slurm.base:17.11.5 .
```

Verify image build

```console
$ docker images
REPOSITORY             TAG                 IMAGE ID            CREATED                  SIZE
mjstealey/slurm.base   17.11.5             1600621cb483        Less than a second ago   819MB
...
```

All images defined in `docker-compose.yml` will be built from the `mjstealey/slurm.base:17.11.5` base image

## Usage

An example [docker-compose.yml](docker-compose.yml) file is provided that builds and deploys the diagramed topology (`-d` is used to daemonize the call).

```
docker-compose up -d
```

Four containers should be observed running when completed

```console
$ docker ps
CONTAINER ID        IMAGE                                COMMAND                  CREATED             STATUS              PORTS                                              NAMES
995183e9391e        mjstealey/slurm.worker:17.11.5       "/usr/local/bin/tini…"   10 seconds ago      Up 30 seconds       22/tcp, 3306/tcp, 6817-6819/tcp, 60001-63000/tcp   worker01
bdd7c8daaca2        mjstealey/slurm.database:17.11.5     "/usr/local/bin/tini…"   10 seconds ago      Up 30 seconds       22/tcp, 3306/tcp, 6817-6819/tcp, 60001-63000/tcp   database
a8382a486989        mjstealey/slurm.worker:17.11.5       "/usr/local/bin/tini…"   10 seconds ago      Up 30 seconds       22/tcp, 3306/tcp, 6817-6819/tcp, 60001-63000/tcp   worker02
24e951854109        mjstealey/slurm.controller:17.11.5   "/usr/local/bin/tini…"   11 seconds ago      Up 31 seconds       22/tcp, 3306/tcp, 6817-6819/tcp, 60001-63000/tcp   controller
```

## Example Slurm interaction

### controller

Use the `docker exec` call to gain a shell on the `controller` container.

```console
$ docker exec -ti controller /bin/bash
[root@controller /]#
```

Issue an `sinfo` call

```console
# sinfo -lN
Wed Apr 11 21:15:35 2018
NODELIST   NODES PARTITION       STATE CPUS    S:C:T MEMORY TMP_DISK WEIGHT AVAIL_FE REASON
worker01       1   docker*        idle    1    1:1:1   1998        0      1   (null) none
worker02       1   docker*        idle    1    1:1:1   1998        0      1   (null) none
```

Create a `worker` account and `worker` user in Slurm

```console
# sacctmgr -i add account worker description="worker account" Organization=Slurm-in-Docker
 Adding Account(s)
  worker
 Settings
  Description     = worker account
  Organization    = slurm-in-docker
 Associations
  A = worker     C = snowflake
 Settings
  Parent        = root

# sacctmgr -i create user worker account=worker adminlevel=None
 Adding User(s)
  worker
 Settings =
  Admin Level     = None
 Associations =
  U = worker    A = worker     C = snowflake
 Non Default Settings
```

### database

Use the `docker exec` call to gain a MariaDB/MySQL shell on the `database` container.

```console
$ docker exec -ti database mysql -uslurm -ppassword -hdatabase.local.dev
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 9
Server version: 5.5.56-MariaDB MariaDB Server

Copyright (c) 2000, 2017, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MariaDB [(none)]>
```

Checkout the `slurm_acct_db` database and it's tables

```console
MariaDB [(none)]> use slurm_acct_db;
Reading table information for completion of table and column names
You can turn off this feature to get a quicker startup with -A

Database changed
MariaDB [slurm_acct_db]> show tables;
+-----------------------------------+
| Tables_in_slurm_acct_db           |
+-----------------------------------+
| acct_coord_table                  |
| acct_table                        |
| clus_res_table                    |
| cluster_table                     |
| convert_version_table             |
| federation_table                  |
| qos_table                         |
| res_table                         |
| snowflake_assoc_table             |
| snowflake_assoc_usage_day_table   |
| snowflake_assoc_usage_hour_table  |
| snowflake_assoc_usage_month_table |
| snowflake_event_table             |
| snowflake_job_table               |
| snowflake_last_ran_table          |
| snowflake_resv_table              |
| snowflake_step_table              |
| snowflake_suspend_table           |
| snowflake_usage_day_table         |
| snowflake_usage_hour_table        |
| snowflake_usage_month_table       |
| snowflake_wckey_table             |
| snowflake_wckey_usage_day_table   |
| snowflake_wckey_usage_hour_table  |
| snowflake_wckey_usage_month_table |
| table_defs_table                  |
| tres_table                        |
| txn_table                         |
| user_table                        |
+-----------------------------------+
29 rows in set (0.00 sec)
```

Validate that the `worker` user was entered into the database

```console
MariaDB [slurm_acct_db]> select * from user_table;
+---------------+------------+---------+--------+-------------+
| creation_time | mod_time   | deleted | name   | admin_level |
+---------------+------------+---------+--------+-------------+
|    1523481120 | 1523481120 |       0 | root   |           3 |
|    1523481795 | 1523481795 |       0 | worker |           1 |
+---------------+------------+---------+--------+-------------+
2 rows in set (0.00 sec)
```

### worker01 and worker02

Use the `docker exec` call to gain a shell on either the `worker01` or `worker02` container and become the user `worker`.

```console
$ docker exec -ti -u worker worker01 /bin/bash
[worker@worker01 /]$ cd ~
[worker@worker01 ~]$ pwd
/home/worker
```

Test password-less `ssh` between containers

```console
[worker@worker01 ~]$ hostname
worker01.local.dev
[worker@worker01 ~]$ ssh worker02
[worker@worker02 ~]$ hostname
worker02.local.dev
[worker@worker02 ~]$ ssh controller
[worker@controller ~]$ hostname
controller.local.dev
```

### Slurm commands

All commands are issued as the user `worker` from the `controller` node

```console
$ docker exec -ti -u worker controller /bin/bash
[worker@controller /]$ cd ~
[worker@controller ~]$ pwd
/home/worker
```

- For the rest of this section the `[worker@controller ~]$` prompt will be shortend to simply `$`

Test the `sacct` and `srun` calls

```console
$ sacct
       JobID    JobName  Partition    Account  AllocCPUS      State ExitCode
------------ ---------- ---------- ---------- ---------- ---------- --------
$ srun -N 2 hostname
worker01.local.dev
worker02.local.dev
$ sacct
       JobID    JobName  Partition    Account  AllocCPUS      State ExitCode
------------ ---------- ---------- ---------- ---------- ---------- --------
2              hostname     docker     worker          2  COMPLETED      0:0
```

Test the `sbatch` call

Make a job file named: `slurm_test.job`

```bash
#!/bin/bash

#SBATCH --job-name=SLURM_TEST
#SBATCH --output=SLURM_TEST.out
#SBATCH --error=SLURM_TEST.err
#SBATCH --partition=docker

srun hostname | sort
```

Run the job using `sbatch`

```console
$ sbatch -N 2 slurm_test.job
Submitted batch job 3
```

Check the `sacct` output

```console
$ sacct
       JobID    JobName  Partition    Account  AllocCPUS      State ExitCode
------------ ---------- ---------- ---------- ---------- ---------- --------
2              hostname     docker     worker          2  COMPLETED      0:0
3            SLURM_TEST     docker     worker          2  COMPLETED      0:0
3.batch           batch                worker          1  COMPLETED      0:0
3.0            hostname                worker          2  COMPLETED      0:0
```

Check the output files

```console
$ ls -1
SLURM_TEST.err
SLURM_TEST.out
slurm_test.job
$ cat SLURM_TEST.out
worker01.local.dev
worker02.local.dev
```

Test the `sbatch --array` and `squeue` calls

Make a job file named `array_test.job`:

```bash
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

snooze=$(( ( RANDOM % 10 )  + 1 ))
echo "$(hostname) is snoozing for ${snooze} seconds..."

sleep $snooze
```

This job defines output directories as being `%N` which reflect the `SLURMD_NODENAME` variable. The output directories will need to exist ahead of time in this particular case, and can be determined by finding all available nodes in the `NODELIST` and creating the directories.

```console
$ sinfo -N
NODELIST   NODES PARTITION STATE
worker01       1   docker* idle
worker02       1   docker* idle
$ mkdir worker01 worker02
```

The job when run will direct it's output files to the directory defined by the node on which it is running. Each iteration will sleep from 1 to 10 seconds randomly before moving onto the next run in the array.

We will run an array of 20 jobs, 2 at a time, until the array is completed. The status can be found using the `squeue` command.

```console
$ sbatch --array=1-20%2 array_test.job
Submitted batch job 4
$ squeue
             JOBID PARTITION     NAME     USER ST       TIME  NODES NODELIST(REASON)
        4_[3-20%2]    docker array_te   worker PD       0:00      1 (JobArrayTaskLimit)
               4_1    docker array_te   worker  R       0:01      1 worker01
               4_2    docker array_te   worker  R       0:01      1 worker02
...
$ squeue
             JOBID PARTITION     NAME     USER ST       TIME  NODES NODELIST(REASON)
          4_[20%2]    docker array_te   worker PD       0:00      1 (JobArrayTaskLimit)
              4_19    docker array_te   worker  R       0:04      1 worker02
              4_18    docker array_te   worker  R       0:10      1 worker01
$ squeue
             JOBID PARTITION     NAME     USER ST       TIME  NODES NODELIST(REASON)
```

Looking into each of the `worker01` and `worker02` directories we can see which jobs were run on each node.

```console
$ ls
SLURM_TEST.err  array_test.job  worker01
SLURM_TEST.out  slurm_test.job  worker02
$ ls worker01
4_11_err.txt  4_16_err.txt  4_1_err.txt   4_3_err.txt  4_7_err.txt
4_11_out.txt  4_16_out.txt  4_1_out.txt   4_3_out.txt  4_7_out.txt
4_14_err.txt  4_18_err.txt  4_20_err.txt  4_5_err.txt  4_9_err.txt
4_14_out.txt  4_18_out.txt  4_20_out.txt  4_5_out.txt  4_9_out.txt
$ ls worker02
4_10_err.txt  4_13_err.txt  4_17_err.txt  4_2_err.txt  4_6_err.txt
4_10_out.txt  4_13_out.txt  4_17_out.txt  4_2_out.txt  4_6_out.txt
4_12_err.txt  4_15_err.txt  4_19_err.txt  4_4_err.txt  4_8_err.txt
4_12_out.txt  4_15_out.txt  4_19_out.txt  4_4_out.txt  4_8_out.txt
```

And looking at each `*_out.txt` file view the output

```console
$ cat worker01/4_14_out.txt
worker01.local.dev is snoozing for 10 seconds...
$ cat worker02/4_6_out.txt
worker02.local.dev is snoozing for 7 seconds...
```

Using the `sacct` call we can see when each job in the array was executed

```console
$ sacct
       JobID    JobName  Partition    Account  AllocCPUS      State ExitCode
------------ ---------- ---------- ---------- ---------- ---------- --------
2              hostname     docker     worker          2  COMPLETED      0:0
3            SLURM_TEST     docker     worker          2  COMPLETED      0:0
3.batch           batch                worker          1  COMPLETED      0:0
3.0            hostname                worker          2  COMPLETED      0:0
4_20         array_tes+     docker     worker          1  COMPLETED      0:0
4_20.batch        batch                worker          1  COMPLETED      0:0
4_1          array_tes+     docker     worker          1  COMPLETED      0:0
4_1.batch         batch                worker          1  COMPLETED      0:0
4_2          array_tes+     docker     worker          1  COMPLETED      0:0
4_2.batch         batch                worker          1  COMPLETED      0:0
4_3          array_tes+     docker     worker          1  COMPLETED      0:0
4_3.batch         batch                worker          1  COMPLETED      0:0
4_4          array_tes+     docker     worker          1  COMPLETED      0:0
4_4.batch         batch                worker          1  COMPLETED      0:0
4_5          array_tes+     docker     worker          1  COMPLETED      0:0
4_5.batch         batch                worker          1  COMPLETED      0:0
4_6          array_tes+     docker     worker          1  COMPLETED      0:0
4_6.batch         batch                worker          1  COMPLETED      0:0
4_7          array_tes+     docker     worker          1  COMPLETED      0:0
4_7.batch         batch                worker          1  COMPLETED      0:0
4_8          array_tes+     docker     worker          1  COMPLETED      0:0
4_8.batch         batch                worker          1  COMPLETED      0:0
4_9          array_tes+     docker     worker          1  COMPLETED      0:0
4_9.batch         batch                worker          1  COMPLETED      0:0
4_10         array_tes+     docker     worker          1  COMPLETED      0:0
4_10.batch        batch                worker          1  COMPLETED      0:0
4_11         array_tes+     docker     worker          1  COMPLETED      0:0
4_11.batch        batch                worker          1  COMPLETED      0:0
4_12         array_tes+     docker     worker          1  COMPLETED      0:0
4_12.batch        batch                worker          1  COMPLETED      0:0
4_13         array_tes+     docker     worker          1  COMPLETED      0:0
4_13.batch        batch                worker          1  COMPLETED      0:0
4_14         array_tes+     docker     worker          1  COMPLETED      0:0
4_14.batch        batch                worker          1  COMPLETED      0:0
4_15         array_tes+     docker     worker          1  COMPLETED      0:0
4_15.batch        batch                worker          1  COMPLETED      0:0
4_16         array_tes+     docker     worker          1  COMPLETED      0:0
4_16.batch        batch                worker          1  COMPLETED      0:0
4_17         array_tes+     docker     worker          1  COMPLETED      0:0
4_17.batch        batch                worker          1  COMPLETED      0:0
4_18         array_tes+     docker     worker          1  COMPLETED      0:0
4_18.batch        batch                worker          1  COMPLETED      0:0
4_19         array_tes+     docker     worker          1  COMPLETED      0:0
4_19.batch        batch                worker          1  COMPLETED      0:0
```

## Tear down

The containers can be stopped and removed using `docker-compose`

```console
$ docker-compose stop
Stopping worker01   ... done
Stopping database   ... done
Stopping worker02   ... done
Stopping controller ... done
$ docker-compose rm -f
Going to remove worker01, database, worker02, controller
Removing worker01   ... done
Removing database   ... done
Removing worker02   ... done
Removing controller ... done
```

The network and volumes can be removed using their representative `docker` commands

- Volumes

    ```console
    $ docker volume list
    DRIVER              VOLUME NAME
    ...
    local               slurmindocker_home
    local               slurmindocker_secret
    local               slurmindocker_storage
    $ docker volume rm slurmindocker_home slurmindocker_secret slurmindocker_storage
    slurmindocker_home
    slurmindocker_secret
    slurmindocker_storage
    ```

- Network

    ```console
    $ docker network list
    NETWORK ID          NAME                    DRIVER              SCOPE
    ...
    a94c168fb653        slurmindocker_slurm     bridge              local
    $ docker network rm slurmindocker_slurm
    slurmindocker_slurm
    ```

## References

Slurm workload manager: [https://www.schedmd.com/index.php](https://www.schedmd.com/index.php)

- Slurm is a highly configurable open-source workload manager. In its simplest configuration, it can be installed and configured in a few minutes (see [Caos NSA and Perceus: All-in-one Cluster Software Stack](http://www.linux-mag.com/id/7239/1/) by Jeffrey B. Layton). Use of optional plugins provides the functionality needed to satisfy the needs of demanding HPC centers. More complex configurations rely upon a database for archiving accounting records, managing resource limits by user or bank account, and supporting sophisticated scheduling algorithms.

Docker: [https://www.docker.com](https://www.docker.com)

- Docker is the company driving the container movement and the only container platform provider to address every application across the hybrid cloud. Today’s businesses are under pressure to digitally transform but are constrained by existing applications and infrastructure while rationalizing an increasingly diverse portfolio of clouds, datacenters and application architectures. Docker enables true independence between applications and infrastructure and developers and IT ops to unlock their potential and creates a model for better collaboration and innovation.
