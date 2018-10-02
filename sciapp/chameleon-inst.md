# Chameleon GFS Instructions

**WORK IN PROGRESS**

The instructions contain the steps necesary to configure and submit a slurm-in-docker SciApp, using [Chameleon Cloud](https://www.chameleoncloud.org/) resources.

## Contents

1. [GlusterFS](GlusterFS) - Start a cluster of GFS storage servers using a Chameleon [complex appliance](https://chameleoncloud.readthedocs.io/en/latest/technical/complex.html).
2. [GFS-Client](GFS-Client) - Start a docker container locally to act as a client to the GFS servers.
3. [Modules](Modules) - Build [LMod](https://lmod.readthedocs.io/en/latest/) modules using the [lmod-modules-centos](https://github.com/scidas/lmod-modules-centos) framework, or use those already available to easily provide system-wide access to workflow software.
4. [SciApp](SciApp) - Configure and submit a SciApp using the [SciDAS API](http://129.114.108.45:9191/api/ui) to deploy your personalized cluster on a SciDAS Endpoint.
5. [Nextflow](Nextflow) - As an example use case, download and deploy [GEMmaker](https://github.com/SystemsGenetics/GEMmaker), a scientific workflow, across the entire cluster.

## GlusterFS

Most scientific applications of slurm-in-docker will require a larger amount of disk space than what is available on the compute nodes that make up a SciDAS endpoint. To solve this, users will mount a separate cluster of storage servers to both the running SciApp and their local machine. This will allow for dynamic allacation of storage as needed, while providing a conduit between the user's local machine and their SciApp. 

For this use case, a GlusterFS cluster will be instantiated using a Chameleon [complex appliance](https://chameleoncloud.readthedocs.io/en/latest/technical/complex.html). This cluster will then be mounted to both a client program and the slurm-in-docker SciApp as they are deployed. 

Details about the GFS complex appliance can be found [here](https://www.chameleoncloud.org/appliances/57/)

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

From a local terminal, navigate to ```slurm-in-docker/gfs-client/client``` and open [docker-compose.yml](https://github.com/SciDAS/slurm-in-docker/blob/glusterfs/gfs-client/client/docker-compose.yml). E

Edit the ```EXTRA_HOSTS``` and ```GFS_SERVERS``` arguments to something like the 3-node example below:
```
 ....
EXTRA_HOSTS: '129.114.109.13:glusterfs 129.114.108.195:gluster-w0 129.114.109.196:gluster-w1' 
GFS_SERVERS: 'glusterfs' # <-- node_name from above
 ....
```
```EXTRA_HOSTS``` should list the hostname and floating IP of each GFS node. ```GFS_SERVERS``` should be the hostname of the "master" GFS node, which is "glusterfs" by default.

### Deployment

To start the container, simply run ```docker-compose up```. Monitor the mounting for any errors. 

After the client has succesfully mounted, open a new terminal and enter ```docker exec -ti client /bin/bash``` to enter the container.

Navigate to ```/mnt``` and check to make sure the local docker volume ```/mnt/data-port``` and the GFS volume ```/mnt/gv0``` are present. 

Confirm there is a ```./data-port``` in your local ```slurm-in-docker/gfs-client/client``` directory, then test by moving a small file into ```data-port/``` from your local machine then into ```/mnt/gv0``` from the client container. 

This is how data can easily be transferred between the local machine and the SciApp.

Finally, navigate to ```/mnt/gv0``` and run ```mkdir home .secret modules modulefiles```. These folders are mounted to various places in the SciApp.

## Modules

Because the infinite nature of workflow-specific software, slurm-in-docker cannot come preconfigured with all the software a workflow depends on. Dependencies will be handled by the [LMod](https://lmod.readthedocs.io/en/latest/) module system. The user can use existing modules, but will likely have to build them using the [lmod-modules-centos](https://github.com/scidas/lmod-modules-centos) framework. After all modules are built, the generated .tar.gz and .lua files will need to be tranferred to the GFS servers. 

Create modules/modulefiles folders in ```./data-port``` with ```mkdir modules modulefiles```.

Create a folder for each piece of software within each directory using ```mkdir -p modules/git modulefiles/git```.

Copy generated files into each directory using ```cp ./2.17.0 modulefiles/git``` and ```cp ./git-2.17.0.tar.gz modules/git```.

Untar the module with ```tar -xzf git-2.17.0.tar.gz```. 

Once all modules are built, copy the files to the GFS servers with ```cp /mnt/data-port/modules /mnt/data-port/modulefiles /mnt/gv0```.

## SciApp

The slurm-in-docker SciApp will instantiate a [Slurm](https://slurm.schedmd.com/) cluster of one master node, one database node, and N compute nodes. Before this, a "framework" file must be configured.

### Configuration

Open [slurm-gfs.json](https://github.com/SciDAS/slurm-in-docker/blob/glusterfs/sciapp/slurm-gfs.json) and modify it to fit your specific needs. 

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
After the .json file has been configured, submit the SciApp with ```curl -X POST -d @htc.json <SciDAS-Endpoint-URL>/appliance```. 

### SSH 

The user will access the running cluster by SSHing into the "controller" node. To do this:

First, find the external IP of "controller" by matching the internal IP on DC/OS with the floating IP on the "Instances" tab on Chameleon.

In the client container running locally, go to the directory ```/mnt/gv0/.secret/root_ssh_controller/```

If the startup was successful, the command ```ls``` should ouput ```id_rsa id_rsa.pub```, the public and private keys shared by the cluster. 

Copy these keys to your local ```~/.ssh``` folder(not inside the client container). It is reccommended that the keys be removed from the GFS server at this point for security purposes. 

In your local ```~/.ssh``` folder:

Set proper permissions for the new key pair with ```chmod 400 id_rsa id_rsa.pub```

Add the public IP in format ```ext_ip ssh-rsa .....``` to the bottom of ```known_hosts```.

Add the private IP to your system with 	```ssh-add id_rsa```

Then access the cluster with ```ssh -i authorized_keys -p 20022 root@<NODE_IP>```

## Nextflow



