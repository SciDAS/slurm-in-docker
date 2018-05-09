# Using Lmod with Slurm-in-Docker

This tutorial makes use of the [docker-compose-lmod.yml](https://github.com/scidas/slurm-in-docker/blob/master/docker-compose-lmod.yml) which defines two additional volume mounts.

1. `modules` - pre-compiled binary files that will be reference by the `module` or `ml` commands in `lmod`
2. `modulefiles` - pre-defined Lua scripts that enable the proper file linkage and environment definitions for the modules.

The version of [Lmod](http://lmod.readthedocs.io/en/latest/index.html) being used predefines a few paths for which it will look for modulefiles that define the modules.

```
MODULEPATH= \
  /opt/apps/modulefiles/Linux: \
  /opt/apps/modulefiles/Core: \
  /opt/apps/lmod/lmod/modulefiles/Core
```

We are going to choose `/opt/apps/modulefiles/Linux` to define the hierarchy for our modulefiles and define a corresponding modules directory in `/opt/apps/Linux` using a similar hierarchy.

- Our modules: `/opt/apps/Linux/PACKAGE/PACKAGE_FILES`
- Our modulefiles: `/opt/apps/modulefiles/Linux/PACKAGE/PACKAGE_LUA_SCRIPT`

## Adding modules

The [lmod-modules-centos](https://github.com/scidas/lmod-modules-centos) repository defines how to make Lmod modules specific to the CentOS 7 based [Slurm in Docker](https://github.com/scidas/slurm-in-docker) project.

Once built, the modules and modulefiles need to be copied into the corresponding `modules` and `modulefiles` directories using a specific directory structure.

Using java 8 as an example, we'd populate the directories as such.

- Assumes the [slurm-in-docker](https://github.com/scidas/slurm-in-docker) and [lmod-modules-centos](https://github.com/scidas/lmod-modules-centos) repositories are at the same directory level on the host for relative path commands.
- Module versions used herein are for reference purposes and subject to change as updates occur.

### create `modules` and `modulefiles` directories for java

Create new directories to hold the module and module file information for java packages

```
cd slurm-in-docker
mkdir -p modules/java modulefiles/java
```

### copy `java/jdk1.8_171` module and module file

Copy the precompiled module files and Lua script module file definition to the appropriate location.

```
cp ../lmod-modules-centos/java/1.8.0_171/jdk1.8.0_171.tar.gz modules/java/jdk1.8.0_171.tar.gz
cp ../lmod-modules-centos/java/1.8.0_171/1.8.0_171.lua modulefiles/java/1.8.0_171.lua
cd modules/java/
tar -xzf jdk1.8.0_171.tar.gz
rm -f jdk1.8.0_171.tar.gz
cd -
```

### test java module

Using the [docker-compose-lmod.yml](https://github.com/scidas/slurm-in-docker/blob/master/docker-compose-lmod.yml) file, test the newly created java module.

The docker-compose-lmod.yml definition add two new volume mounts which make the modules and modulefiles available to the controller and worker nodes at run time.

```console
$ docker-compose -f docker-compose-lmod.yml up -d
Creating network "slurmindocker_slurm" with the default driver
Creating volume "slurmindocker_home" with default driver
Creating volume "slurmindocker_secret" with default driver
Creating controller ... done
Creating worker01   ... done
Creating database   ... done
Creating worker02   ... done
```

Use docker exec to get onto the controller node

```
docker exec -ti controller /bin/bash
```

List available modules using `module avail`

```console
# module avail

 /opt/apps/modulefiles/Linux -
   java/1.8.0_171

 /opt/apps/lmod/lmod/modulefiles/Core
   lmod/7.7    settarg/7.7

Use "module spider" to find
all possible modules.
Use "module keyword key1 key2
..." to search for all
possible modules matching any
of the "keys".
```

We can see our newly added `java/1.8.0_171` as an option.

Try the `java -version` command prior to loading the module.

```console
# java -version
bash: java: command not found
```

Next, load the java module and try the same command again.

```console
# module load java
# java -version
java version "1.8.0_171"
Java(TM) SE Runtime Environment (build 1.8.0_171-b11)
Java HotSpot(TM) 64-Bit Server VM (build 25.171-b11, mixed mode)
```

Use the `which` command to see where java was installed.

```console
# which java
/opt/apps/Linux/java/jdk1.8.0_171/bin/java
```

Unload the module and try the `which` command again.

```console
# module unload java
# which java
/usr/bin/which: no java in (/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin)
```

Exit the controller node

```console
# exit
```

### tear down the cluster

Stop the running containers, remove the volume and network defintions

```
docker-compose -f docker-compose-lmod.yml stop
docker-compose -f docker-compose-lmod.yml rm -f
docker volume rm slurmindocker_home slurmindocker_secret -f
docker network rm slurmindocker_slurm
```

## Nextflow

[Nextflow](https://www.nextflow.io) - Data-driven computational pipelines

- Nextflow enables scalable and reproducible scientific workflows using software containers. It allows the adaptation of pipelines written in the most common scripting languages.
- Its fluent DSL simplifies the implementation and the deployment of complex parallel and reactive workflows on clouds and clusters.

The Nextflow packages have a dependency on Java, so in order to enable Nextflow as a module within our Slurm cluster we also have to ensure it's dependencies are also installed prior to running it. See the [nextflow modulefiles definition]() for how this is done.

Learn more about Nextflow from the [official docs](https://www.nextflow.io/docs/latest/index.html)
### Goal

Enable the Nextflow module within the Slurm cluster and run a hello world workflow accross our two worker nodes.

- Assumes the [slurm-in-docker](https://github.com/scidas/slurm-in-docker) and [lmod-modules-centos](https://github.com/scidas/lmod-modules-centos) repositories are at the same directory level on the host for relative path commands.
- Module versions used herein are for reference purposes and subject to change as updates occur.

### create `modules` and `modulefiles` directories for java

Create new directories to hold the module and module file information for java and nextflow packages

```
cd slurm-in-docker
mkdir -p \
  modules/java \
  modulefiles/java \
  modules/nextflow \
  modulefiles/nextflow
```

### copy `java` and `nextflow` modules and module files

Copy the precompiled module files and Lua script module file definition to the appropriate location.

```
cp ../lmod-modules-centos/java/1.8.0_171/jdk1.8.0_171.tar.gz \
  modules/java/jdk1.8.0_171.tar.gz
cp ../lmod-modules-centos/java/1.8.0_171/1.8.0_171.lua \
  modulefiles/java/1.8.0_171.lua
cp ../lmod-modules-centos/nextflow/0.28.0/nextflow-0.28.0.tar.gz \
  modules/nextflow/nextflow-0.28.0.tar.gz
cp ../lmod-modules-centos/nextflow/0.28.0/0.28.0.lua \
  modulefiles/nextflow/0.28.0.lua
cd modules/java/
tar -xzf jdk1.8.0_171.tar.gz
rm -f jdk1.8.0_171.tar.gz
cd -
cd modules/nextflow/
tar -xzf nextflow-0.28.0.tar.gz
rm -f nextflow-0.28.0.tar.gz
cd -
```

### test nextflow module

Using the [docker-compose-lmod.yml](https://github.com/scidas/slurm-in-docker/blob/master/docker-compose-lmod.yml) file, test the newly created nextflow module.

```
docker-compose -f docker-compose-lmod.yml up -d
```

Add the **worker** user to the Slurm database

```console
$ docker exec controller bash -c 'sacctmgr -i add account worker description="worker account" Organization=Slurm-in-Docker'
 Adding Account(s)
  worker
 Settings
  Description     = worker account
  Organization    = slurm-in-docker
 Associations
  A = worker     C = snowflake
 Settings
  Parent        = root
$ docker exec controller bash -c 'sacctmgr -i create user worker account=worker adminlevel=None'
 Adding User(s)
  worker
 Settings =
  Admin Level     = None
 Associations =
  U = worker    A = worker     C = snowflake
 Non Default Settings
```

Log onto the **controller** node as the **worker** user and change to the `$HOME` directory.

```console
$ docker exec -ti -u worker controller /bin/bash
[worker@controller /]$ cd ~
[worker@controller ~]$ pwd
/home/worker
```

See what modules are available

```console
$ module avail

 /opt/apps/modulefiles/Linux -
   java/1.8.0_171
   nextflow/0.28.0

 /opt/apps/lmod/lmod/modulefiles/Core
   lmod/7.7    settarg/7.7

Use "module spider" to find
all possible modules.
Use "module keyword key1 key2
..." to search for all
possible modules matching any
of the "keys".
```

Load the **nextflow** module and check version (**java** is a dependency)

```console
$ module load nextflow
Lmod has detected the
following error:  Cannot
load module "nextflow/0.28.0"
without these module(s)
loaded:
   java

While processing the following module(s):
    Module fullname  Module Filename
    ---------------  ---------------
    nextflow/0.28.0  /opt/apps/modulefiles/Linux/nextflow/0.28.0.lua

$ module load java nextflow
$ module list

Currently Loaded Modules:
  1) java/1.8.0_171
  2) nextflow/0.28.0
$ nextflow -version

      N E X T F L O W
      version 0.28.0 build 4779
      last modified 10-03-2018 12:13 UTC
      cite doi:10.1038/nbt.3820
      http://nextflow.io

```

### nextflow run hello

Nextflow has a hello-world style workflow that can be invoked by calling `nextflow run hello`. Run this and notice what occurs on the system.

```console
$ nextflow run hello
N E X T F L O W  ~  version 0.28.0
Pulling nextflow-io/hello ...
 downloaded from https://github.com/nextflow-io/hello.git
Launching `nextflow-io/hello` [desperate_curie] - revision: d4c9ea84de [master]
[warm up] executor > local
[99/aa6988] Submitted process > sayHello (3)
[62/a1e3cd] Submitted process > sayHello (1)
[92/c892fa] Submitted process > sayHello (4)
[57/9ce3ec] Submitted process > sayHello (2)
Hello world!
Ciao world!
Hola world!
Bonjour world!
```

This call fetched content from the nextflow-io site and added it to the user's home directory in `$HOME/.nextflow` and put any log infromation into a file named `$HOME/.nextflow.log`.

```console
$ ls -alh $HOME | grep .nextflow
drwxrwxr-x 3 worker worker 4.0K Apr 22 17:53 .nextflow
-rw-rw-r-- 1 worker worker 7.0K Apr 22 17:53 .nextflow.log
```

Contents of `$HOME/.nextflow`:

```console
$ tree -a .nextflow
.nextflow
|-- cache
|   `-- 09a64642-04bc-44c4-859a-99b5568fdbf1
|       |-- db
|       |   |-- 000003.log
|       |   |-- CURRENT
|       |   |-- LOCK
|       |   `-- MANIFEST-000002
|       `-- index.desperate_curie
`-- history

3 directories, 6 files
```

### nextflow Slurm job

Create a job defintion named `nextflow_test.job` that will allocate both worker nodes to run `nextflow run hello`.

File `nextflow_test.job`:

```bash
#!/bin/bash

#SBATCH --job-name=nextflow_test
#SBATCH --output=%A_%a_out.txt
#SBATCH --error=%A_%a_err.txt
#SBATCH -p docker
#SBATCH -n 2

module load java nextflow

# Run your executable
srun nextflow run hello
```

Run the batch job, check the `squeue` and `sacct` status as the job runs.

```console
$ sbatch nextflow_test.job
Submitted batch job 2
$ squeue
             JOBID PARTITION     NAME     USER ST       TIME  NODES NODELIST(REASON)
                 2    docker nextflow   worker  R       0:01      2 worker[01-02]
$ sacct
       JobID    JobName  Partition    Account  AllocCPUS      State ExitCode
------------ ---------- ---------- ---------- ---------- ---------- --------
2            nextflow_+     docker     worker          2    RUNNING      0:0
2.0            nextflow                worker          2    RUNNING      0:0
$ squeue
             JOBID PARTITION     NAME     USER ST       TIME  NODES NODELIST(REASON)
                 2    docker nextflow   worker  R       0:06      2 worker[01-02]
$ sacct
       JobID    JobName  Partition    Account  AllocCPUS      State ExitCode
------------ ---------- ---------- ---------- ---------- ---------- --------
2            nextflow_+     docker     worker          2    RUNNING      0:0
2.0            nextflow                worker          2    RUNNING      0:0
$ squeue
             JOBID PARTITION     NAME     USER ST       TIME  NODES NODELIST(REASON)
                 2    docker nextflow   worker  R       0:10      2 worker[01-02]
$ sacct
       JobID    JobName  Partition    Account  AllocCPUS      State ExitCode
------------ ---------- ---------- ---------- ---------- ---------- --------
2            nextflow_+     docker     worker          2    RUNNING      0:0
2.0            nextflow                worker          2    RUNNING      0:0
$ squeue
             JOBID PARTITION     NAME     USER ST       TIME  NODES NODELIST(REASON)
                 2    docker nextflow   worker  R       0:14      2 worker[01-02]
$ sacct
       JobID    JobName  Partition    Account  AllocCPUS      State ExitCode
------------ ---------- ---------- ---------- ---------- ---------- --------
2            nextflow_+     docker     worker          2  COMPLETED      0:0
2.batch           batch                worker          1  COMPLETED      0:0
2.0            nextflow                worker          2  COMPLETED      0:0
$ squeue
             JOBID PARTITION     NAME     USER ST       TIME  NODES NODELIST(REASON)
```

When the job completes check the output files

```console
$ ls -1
2_4294967294_err.txt
2_4294967294_out.txt
nextflow_test.job
work
```

File `2_4294967294_out.txt`:

```console
$ cat 2_4294967294_out.txt
N E X T F L O W  ~  version 0.28.0
N E X T F L O W  ~  version 0.28.0
Launching `nextflow-io/hello` [intergalactic_lumiere] - revision: d4c9ea84de [master]
Launching `nextflow-io/hello` [mad_lamarr] - revision: d4c9ea84de [master]
[warm up] executor > local
[warm up] executor > local
[87/02d3d1] Submitted process > sayHello (2)
[f1/ae6512] Submitted process > sayHello (3)
[2c/cbb8b7] Submitted process > sayHello (1)
[bd/07859c] Submitted process > sayHello (4)
[f6/1fda34] Submitted process > sayHello (4)
[bc/47a180] Submitted process > sayHello (2)
[42/d96ca6] Submitted process > sayHello (3)
[99/330e9b] Submitted process > sayHello (1)
Hola world!
Ciao world!
Hello world!
Ciao world!
Bonjour world!
Hola world!
Hello world!
Bonjour world!
```

File `2_4294967294_err.txt`:

```console
$ cat 2_4294967294_err.txt
```

Contents of `work` directory:

```console
$ tree -a work/
work/
|-- 2c
|   `-- cbb8b721ae27a019c82b94ca6c8695
|       |-- .command.begin
|       |-- .command.err
|       |-- .command.log
|       |-- .command.out
|       |-- .command.run
|       |-- .command.sh
|       `-- .exitcode
|-- 42
|   `-- d96ca6f4e8eeba81c3a5d8a753e4cf
|       |-- .command.begin
|       |-- .command.err
|       |-- .command.log
|       |-- .command.out
|       |-- .command.run
|       |-- .command.sh
|       `-- .exitcode
|-- 57
|   `-- 9ce3ec2c2b5849d73a7c3a3d8c8126
|       |-- .command.begin
|       |-- .command.err
|       |-- .command.log
|       |-- .command.out
|       |-- .command.run
|       |-- .command.sh
|       `-- .exitcode
|-- 62
|   `-- a1e3cd0c1d7d9ec4fe50e90ceef925
|       |-- .command.begin
|       |-- .command.err
|       |-- .command.log
|       |-- .command.out
|       |-- .command.run
|       |-- .command.sh
|       `-- .exitcode
|-- 87
|   `-- 02d3d1c6a01e882d543c6c20ea70c9
|       |-- .command.begin
|       |-- .command.err
|       |-- .command.log
|       |-- .command.out
|       |-- .command.run
|       |-- .command.sh
|       `-- .exitcode
|-- 92
|   `-- c892fae2e088cd3bf11e23305371f8
|       |-- .command.begin
|       |-- .command.err
|       |-- .command.log
|       |-- .command.out
|       |-- .command.run
|       |-- .command.sh
|       `-- .exitcode
|-- 99
|   |-- 330e9b5ecf22bd99dd7f49718eb225
|   |   |-- .command.begin
|   |   |-- .command.err
|   |   |-- .command.log
|   |   |-- .command.out
|   |   |-- .command.run
|   |   |-- .command.sh
|   |   `-- .exitcode
|   `-- aa69886272fdd7a8d4d09f2e40abe3
|       |-- .command.begin
|       |-- .command.err
|       |-- .command.log
|       |-- .command.out
|       |-- .command.run
|       |-- .command.sh
|       `-- .exitcode
|-- bc
|   `-- 47a1809a2198ea57886d4c3f823517
|       |-- .command.begin
|       |-- .command.err
|       |-- .command.log
|       |-- .command.out
|       |-- .command.run
|       |-- .command.sh
|       `-- .exitcode
|-- bd
|   `-- 07859c04437f7bc6833bc09aaf9d48
|       |-- .command.begin
|       |-- .command.err
|       |-- .command.log
|       |-- .command.out
|       |-- .command.run
|       |-- .command.sh
|       `-- .exitcode
|-- f1
|   `-- ae6512ad0f1ced8646c3bcbd4452da
|       |-- .command.begin
|       |-- .command.err
|       |-- .command.log
|       |-- .command.out
|       |-- .command.run
|       |-- .command.sh
|       `-- .exitcode
`-- f6
    `-- 1fda341384faf7760f06da44a11fe9
        |-- .command.begin
        |-- .command.err
        |-- .command.log
        |-- .command.out
        |-- .command.run
        |-- .command.sh
        `-- .exitcode

23 directories, 84 files
```

Also note that new log files have been created.

```console
$ ls -alh $HOME | grep .nextflow
-rw-rw-r--  1 worker worker 6.6K Apr 22 18:13 .nextflow.log
-rw-rw-r--  1 worker worker 6.7K Apr 22 18:13 .nextflow.log.1
-rw-rw-r--  1 worker worker 7.0K Apr 22 17:53 .nextflow.log.2
```

