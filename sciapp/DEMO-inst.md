# DEMO Chameleon GFS Instructions

**WORK IN PROGRESS**

The instructions contain the steps necesary to configure and submit a slurm-in-docker SciApp, using [Chameleon Cloud](https://www.chameleoncloud.org/) resources.

**REQUIREMENTS**

This demo requires the following software to be installed on the user's local machine:

 - [Git](https://git-scm.com/)
 - [Docker](https://www.docker.com/)
 - [docker-compose](https://docs.docker.com/compose/)

You will want to clone the following repos from GitHub:

 - [slurm-in-docker](https://github.com/SciDAS/slurm-in-docker) (branch [glusterfs](https://github.com/SciDAS/slurm-in-docker/tree/glusterfs))
 - [lmod-modules-centos](https://github.com/SciDAS/lmod-modules-centos) (branch [cbmckni](https://github.com/SciDAS/lmod-modules-centos/tree/cbmckni))

Finally, you must have the address to a SciDAS Endpoint. An example using port 9191 looks like this: http://{ENDPOINT_IP}:9191

## Contents

1. [GlusterFS](GlusterFS) - Start a cluster of GFS storage servers using a Chameleon [complex appliance](https://chameleoncloud.readthedocs.io/en/latest/technical/complex.html).
2. [GFS-Client](GFS-Client) - Start a docker container locally to act as a client to the GFS servers.
3. [Modules](Modules) - Build [LMod](https://lmod.readthedocs.io/en/latest/) modules using the [lmod-modules-centos](https://github.com/scidas/lmod-modules-centos) framework, or use those already available to easily provide system-wide access to workflow software.
4. [SciApp](SciApp) - Configure and submit a SciApp using the [SciDAS API](http://129.114.108.45:9191/api/ui) to deploy your personalized cluster on a SciDAS Endpoint.
5. [GEMmaker](GEMmaker) - As an example use case, download and deploy [GEMmaker](https://github.com/SystemsGenetics/GEMmaker), a scientific workflow, across the entire cluster.
6. [Takedown](Takedown) - Take down the cluster with a simple command.

### Definitions

**Execution Environments** 

 - **Local Machine**: The user's local staging point that they use for basic computation(ex. laptop, desktop PC).
 - **GFS Client**: A GFS "client" container running on the user's local machine. 
 - **SciApp**: The running Slurm SciApp. The user should have a SSH connection from their local machine to a shell inside the SciApp.

**Directories**

 - **${SLURM_IN_DOCKER}**: Path to slurm-in-docker repository. (ex. ```/home/slurm-in-docker```)
 - **${LMODS_DOCKER_CENTOS}**: Path to lmods-docker-centos repository. (ex. ```/home/lmods-docker-centos```)

## GlusterFS

Most scientific applications of slurm-in-docker will require a larger amount of disk space than what is available on the compute nodes that make up a SciDAS endpoint. To solve this, users will mount a separate cluster of storage servers to both the running SciApp and their local machine. This will allow for dynamic allacation of storage as needed, while providing a conduit between the user's local machine and their SciApp. 

For this use case, a GlusterFS cluster will be instantiated using a Chameleon [complex appliance](https://chameleoncloud.readthedocs.io/en/latest/technical/complex.html). This cluster will then be mounted to both a client program and the slurm-in-docker SciApp as they are deployed. 

Details about the GFS complex appliance can be found [here](https://www.chameleoncloud.org/appliances/57/).

Make sure each node of the cluster has an **external** IP associated with it!

**DEMO** Create a complex appliance with at least one storage node. Make sure you reserve well in advance because storage nodes are very limited. 

### Allocation

Before a GFS cluster can be deployed on Chameleon, the user must have access to Chameleon and an active lease. 

After a metric for required storage space is determined, request a lease through the [Chameleon "Leases" UI](https://chi.tacc.chameleoncloud.org/dashboard/project/leases/). Make sure to specify the correct number of nodes needed(one storage node should have approximately 32TB of disk space) and to request the "storage" flavor. Once the lease shows an "ACTIVE" status, go to the [Chameleon"Stacks" UI](https://chi.tacc.chameleoncloud.org/dashboard/project/stacks/).

### Deployment

Select ["Launch Stack"](https://chi.tacc.chameleoncloud.org/dashboard/project/stacks/select_template). 

Choose "URL" as the Template Source, then enter <https://www.chameleoncloud.org/appliances/api/appliances/57/template> as the Template URL. 

Select "Next", then fill out the following form. Make sure to use your active lease, and specify N-1 extra gluster nodes, where N is the maximum specified by your lease. 

Select "Launch", then check your stack's status. This may take a while. If the creation results in a "Create Failed" status, it is likely because there are not enough storage nodes available. 

Finally, go to the [Chameleon "Instances" UI](https://chi.tacc.chameleoncloud.org/dashboard/project/instances/) and associate a floating IP with each instance.    

## GFS-Client

If the GFS stack deployed successfully, it should be possible to mount to it through the [gfs-client](https://github.com/SciDAS/slurm-in-docker/tree/glusterfs/gfs-client/client) container.

### Configuration

From the **Local Machine**, navigate to ```**${SLURM_IN_DOCKER}**/gfs-client/client``` and open [docker-compose.yml](https://github.com/SciDAS/slurm-in-docker/blob/glusterfs/gfs-client/client/docker-compose.yml). 

Edit the ```EXTRA_HOSTS``` and ```GFS_SERVERS``` arguments to something like the 3-node example below:
```
 ....
EXTRA_HOSTS: '129.114.109.13:glusterfs 129.114.108.195:gluster-w0 129.114.109.196:gluster-w1' 
GFS_SERVERS: 'glusterfs' # <-- node_name from above
 ....
```
```EXTRA_HOSTS``` should list the hostname and floating IP of each GFS node. ```GFS_SERVERS``` should be the hostname of the "master" GFS node, which is "glusterfs" by default.

### Deployment

To start the container, simply run ```docker-compose up``` in ```**${SLURM_IN_DOCKER}**/gfs-client/client```. Monitor the mounting for any errors. 

After the client has succesfully mounted, open a new terminal and enter ```docker exec -ti client /bin/bash``` to enter the container.

Navigate to ```/mnt``` and check to make sure the local docker volume ```/mnt/data-port``` and the GFS volume ```/mnt/gv0``` are present. 

Confirm there is a ```./data-port``` in your local ```**${SLURM_IN_DOCKER}**/gfs-client/client``` directory, then test by moving a small file into ```data-port/``` from your local machine then into ```/mnt/gv0``` from the client container. 

This is how data can easily be transferred between the local machine and the SciApp.

Finally, navigate to ```/mnt/gv0``` and run ```mkdir home .secret modules modulefiles```. These folders are mounted to the following locations inside the cluster:

 - /mnt/gv0/home:/home/worker
 - /mnt/gv0/.secret:/.secret
 - /mnt/gv0/modules:/opt/apps/Linux
 - /mnt/gv0/modulefiles:/opt/apps/modulefiles/Linux

## Modules

Because the infinite nature of workflow-specific software, slurm-in-docker cannot come preconfigured with all the software a workflow depends on. Dependencies will be handled by the [LMod](https://lmod.readthedocs.io/en/latest/) module system. The user can use existing modules, but will likely have to build them using the [lmod-modules-centos](https://github.com/scidas/lmod-modules-centos) framework. After all modules are built, the generated .tar.gz and .lua files will need to be tranferred to the GFS servers. 


Inside the **GFS Client**:

Create modules/modulefiles folders in ```/mnt/data-port``` with ```mkdir -p /mnt/data-port/modules /mnt/data-port/modulefiles```.

Create a folder for each piece of software within each directory using ```mkdir -p modules/git modulefiles/git```.

Copy generated files into each directory using:

```cp **${LMODS_DOCKER_CENTOS}**/{NAME}/{VERSION}/{VERSION}.lua modulefiles/{NAME}``` and ```cp **${LMODS_DOCKER_CENTOS}**/{NAME}/{VERSION}/{NAME}-{VERSION}.tar.gz modules/{NAME}```

ex. ```cp **${LMODS_DOCKER_CENTOS}**/git/2.17.0/2.17.0.lua modulefiles/git``` and ```cp **${LMODS_DOCKER_CENTOS}**/git/2.17.0/git-2.17.0.tar.gz modules/git```

Untar the module with ```tar -xzf git-2.17.0.tar.gz```. 

Once all modules are built, copy the files to the GFS servers with ```cp /mnt/data-port/modules /mnt/data-port/modulefiles /mnt/gv0```.

**DEMO** Clone the "cbmckni" branch of [lmod-modules-centos](https://github.com/scidas/lmod-modules-centos), then build and transfer the following modules: 
 - General: irods-icommands, nano, java, nextflow, git, python3
 - GEMmaker: fastqc, hisat2, samtools, sratoolkit, stringtie, trimmomatic

## SciApp

The slurm-in-docker SciApp will instantiate a [Slurm](https://slurm.schedmd.com/) cluster of one master node, one database node, and N compute nodes. Before this, a "framework" file must be configured.

### Configuration

From the **Local Machine** in ```**${SLURM_IN_DOCKER}**/sciapp```

Open [slurm-gfs.json](https://github.com/SciDAS/slurm-in-docker/blob/glusterfs/sciapp/slurm-gfs.json) and modify it to fit your specific needs. 

You can also use the script [generate.sh](https://github.com/SciDAS/slurm-in-docker/blob/glusterfs/sciapp/generate.sh) to generate frameworks. 

Required Arguments:
 - $1: SciApp name
 - $2: # of workers
 - $3: # of vCPUs per worker
 - $4: Memory per worker(Mb)
 - $5: Disk per worker(Mb)
 - $6: GFS Server list - ex. "123.456.789.10:glusterfs 123.456.789.11:gluster-w0"

 Ex. ```./generate.sh slurm 6 6 24576 4096 "123.456.789.10:glusterfs 123.456.789.11:gluster-w0"``` will generate the framework for a 6 node cluster mounted to 2 GFS storage nodes.

**DEMO** Use ```./generate.sh slurm 6 6 24576 4096 "129.114.109.172:glusterfs 129.114.109.181:gluster-w0"``` to generate the demo framework. 

For example:
```
{
  "id": "slurm-gfs", # Should be unique and meaningful.
  "containers": [
    {
      "id": "controller",
      "type": "service",
      "resources":
      {
        "cpus": 1,   # Specify these resources 
        "mem": 4096,
        "disk": 8192
      },
      "network_mode": "container",
      "image": "cbmckni/slurm-sciapp-ctld:gfs", # make sure this image is the correct one you want to use, especially if building from source.
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
        "COMPUTE_NODES": "@worker01 @worker02", # hostnames of compute nodes
        "PARTITION_NAME": "docker", 
        "EXTRA_HOSTS": "129.114.109.13:glusterfs 129.114.108.195:gluster-w0 129.114.109.196:gluster-w1", # same as client  
        "GFS_SERVERS": "glusterfs",
        "GFS_SERVER_DIRS": "/gv0/home:/gv0/.secret:/gv0/modules:/gv0/modulefiles",
        "GFS_CLIENT_DIRS": "/home:/.secret:/opt/apps/Linux:/opt/apps/modulefiles/Linux"
      },
      "force_pull_image": true
 ....
```
After the .json file has been configured, submit the SciApp with ```curl -X POST -d @{appName}.json <SciDAS-Endpoint-URL>/appliance```. 

**DEMO** Use ```curl -X POST -d @slurm.json http://129.114.108.45:9191/appliance``` to submit. Visit ```http://129.114.108.45:9191/appliance/slurm/ui``` to see status.

Check if the cluster is running by visiting ```http://{endpointIP}:9191/appliance/{appName}/ui```

### SSH 

The user will access the running cluster by SSHing into the "controller" node. To do this:

First, find the external IP of "controller" by visiting ```http://{endpointIP}:9191/appliance/{appName}/ui```. The IP will be listed beside the controller node.

In the **GFS Client** container, go to the directory ```/mnt/gv0/.secret/root_ssh_controller/```

If the startup was successful, the command ```ls``` should ouput ```id_rsa id_rsa.pub```, the public and private keys shared by the cluster. 

Copy these keys to your ```~/.ssh``` folder on the **Local Machine**.



In the ```~/.ssh``` folder on the **Local Machine**:

Set proper permissions for the new key pair with ```chmod 700 id_rsa id_rsa.pub```

Add the public key in format ```{externalIP} {pubKey}``` to the bottom of ```~/.ssh/known_hosts```.

Add the private key to your system with ```ssh-add id_rsa```

Then access the cluster with ```ssh -i authorized_keys -p 20022 root@{nodeIP}```

### Testing

At this point, run a few tests to make sure everything is working properly:

```
[root@controller ~]# sinfo -lN
Fri Oct 19 23:03:39 2018
NODELIST                                                    NODES PARTITION       STATE CPUS    S:C:T MEMORY TMP_DISK WEIGHT AVAIL_FE REASON              
worker1-slurm.marathon.containerip.dcos.thisdcos.directory      1   docker*        idle    6    6:1:1  24576        0      1   (null) none                
worker2-slurm.marathon.containerip.dcos.thisdcos.directory      1   docker*        idle    6    6:1:1  24576        0      1   (null) none                
worker3-slurm.marathon.containerip.dcos.thisdcos.directory      1   docker*        idle    6    6:1:1  24576        0      1   (null) none                
worker4-slurm.marathon.containerip.dcos.thisdcos.directory      1   docker*        idle    6    6:1:1  24576        0      1   (null) none                
worker5-slurm.marathon.containerip.dcos.thisdcos.directory      1   docker*        idle    6    6:1:1  24576        0      1   (null) none                
worker6-slurm.marathon.containerip.dcos.thisdcos.directory      1   docker*        idle    6    6:1:1  24576        0      1   (null) none                
[root@controller ~]# srun -N 6 hostname
worker5
worker2
worker3
worker6
worker1
worker4
[root@controller ~]# module avail

--------------------------------------------------------------------------------------- /opt/apps/modulefiles/Linux ----------------------------------------------------------------------------------------
   fastqc/0.11.7    hisat2/2.1.0              java/1.8.0_181    nextflow/0.31.0    samtools/1.9        stringtie/1.3.4d
   git/2.17.0       irods-icommands/4.1.11    nano/2.9.6        python3/3.7.0      sratoolkit/2.8.2    trimmomatic/0.38

----------------------------------------------------------------------------------- /opt/apps/lmod/lmod/modulefiles/Core -----------------------------------------------------------------------------------
   lmod/7.7    settarg/7.7

Use "module spider" to find all possible modules.
Use "module keyword key1 key2 ..." to search for all possible modules matching any of the "keys".
```

These tests let you know the nodes and modules are available. See the main slurm-in-docker documentation for more comprehensive tests. 

### Adding "Worker" User

All jobs must be submitted by the ```worker``` user. The steps required to do so are:

As root, create the ```worker``` account and user:
```
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

Switch users with ```su - worker```

Submit jobs, store data, or any other actions that do not require root permissions as ```worker``` from the ```/home/worker``` directory.


**There is now a personal CentOS/Slurm HPC cluster at your fingertips!**


## GEMmaker

**Switch to worker user.** ```su - worker```

Any Nextflow-compatible workflow can be run with slurm-in-docker. As an example slurm-in-docker use case, the next section will detail the steps required to deploy [GEMmaker](https://github.com/SystemsGenetics/GEMmaker), a scientific workflow, across the entire cluster, a workflow that generates Gene Expression Matricies from raw RNA sequences. This will cover using Nextflow workflow manager, adding python3 packages, and more useful slurm-in-docker skills. 

Clone the GEMmaker repository with ```module add git``` and ```git clone https://github.com/SystemsGenetics/GEMmaker.git```

### Input Data

In this case, input RNA sequences will be pulled from [iRODS](https://irods.org/). 

Add the icommands with ```module add irods-icommands```

Connect to iRODS with ```iinit``` and enter your credentials. Test the success with ```ils```

Pull the required data using ```iget {pathToData}```

**DEMO** The unit test directory no longer exists. Instead, create a file named UnitTestSRAs.txt:
```
SRR493289
SRR1696865
SRR2086505
SRR2086497
SRR1184187
SRR1184188
```
Download the reference annotation files with ```iget -rf /scidasZone/sysbio/experiments/Ath_26k/input/reference```


### Python3

**You must be root to add packages.** 

Many applications require Python2.7 or Python3. Most require specific packages that are not available by default. Since all nodes use the same environment modules, it is possible to add new python packages at any point. Here we will outline adding the packages required by the GEMmaker workflow. 

First, add the Python3 module with ```module add python3```

If the repository has a ```requirements.txt``` file, use ```python3 -m pip install -r requirements.txt``` to add the packages.

If not, determine the required packages and add them with ```python3 -m pip install {Package1} {Package2}```

### Nextflow

**Switch back to worker user.** ```su - worker```

Add nextflow with ```module add java nextflow```

#### Configuration 

Make a copy of the file ```nextflow.config.example``` and name it ```nextflow.config```

Edit the following lines in [nextflow.config](https://github.com/SystemsGenetics/GEMmaker/blob/master/nextflow.config.example):
 - Line 31 Set ```remote_list_path``` to ```"/home/worker/GEMmaker/UnitTestSRAs.txt"``` 
 - Line 40 Set ```local_samples_path``` to ```"none"```
 - Line 57 Set ```reference_path``` to ```"/home/worker/GEMmaker/reference"```
 - Line 63 Set ```reference_prefix``` to ```"TAIR10_Araport11"``` 
 - Line 125 Set ```threads``` to ```48``` 
 - Line 368 Set ```queue``` to ```"docker"```

**DEMO** More tweaking may be needed. 

 - Delete Line 104 of [main.nf](https://github.com/SystemsGenetics/GEMmaker/blob/master/main.nf)

#### Deployment

Deploy GEMmaker with ```nextflow run main.nf -profile slurm```

If any errors are encountered, fix them and resume with ```nextflow run main.nf -profile slurm -resume```

### Post Processing

To generate a GEM out of the FPKMs/TPMs, run ```python3 ./scripts/create_GEM.py --source ./ --type TPM --prefix unitTest```

The generated GEM will be the file ```unitTest.GEM.TPM.txt```

## Takedown

After all necesary computation has completed, the cluster can be taken down with ```curl -X DELETE http://{endpointIP}:9191/appliance/{appName}```

**DEMO** Take down with ```curl -X DELETE http://129.114.108.45:9191/appliance/slurm```


