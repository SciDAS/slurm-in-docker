# Swarm based Slurm cluster using GlusterFS

The [Slurm in Docker](https://github.com/scidas/slurm-in-docker) code has been extended to run in a distributed docker cluster using [docker swarm](https://docs.docker.com/engine/swarm/) with shared storage being managed by [GlusterFS](https://www.gluster.org).

The participating nodes are all VMs within the RENCI VMware ESXi cluster (edc).

- mjs-dev-1.edc.renci.org: 172.25.8.43
- mjs-dev-2.edc.renci.org: 172.25.8.44
- mjs-dev-3.edc.renci.org: 172.25.8.47
- mjs-dev-4.edc.renci.org: 172.25.8.48
- galera-1.edc.renci.org: 172.25.8.171
- galera-2.edc.renci.org: 172.25.8.172

## Swarm nodes

The following installation occured on all VMs that will participate in the cluster

- **manager**: mjs-dev-1.edc.renci.org
- **worker**: mjs-dev-2.edc.renci.org
- **worker**: mjs-dev-3.edc.renci.org
- **worker**: mjs-dev-4.edc.renci.org

### docker-ce 

Installation [reference](https://docs.docker.com/engine/installation/linux/centos/)

```
sudo yum install -y yum-utils
sudo yum-config-manager \
  --add-repo \
  https://download.docker.com/linux/centos/docker-ce.repo
sudo yum makecache fast
sudo yum install -y docker-ce
sudo systemctl start docker
sudo systemctl enable docker
sudo groupadd docker
sudo usermod -aG docker $USER
```

As root, create file `/etc/docker/daemon.json` with the following:

```
{
  "storage-driver": "devicemapper"
}
```

Restart docker: `# systemctl restart docker.service`

Verify that devicemapper is now being used.

```console
$ docker info
...
Server Version: 17.12.1-ce
Storage Driver: devicemapper
```

Should now have a `/var/lib/docker/devicemapper` directory

```
# ls /var/lib/docker/devicemapper
devicemapper  metadata
```

Reboot VM, and when it comes back online the `/var/lib/docker/overlay` directory can be deleted as it would be released from system resources.
All further image layers will be written to `/var/lib/docker/devicemapper`.


### docker-compose

Installation [reference](https://docs.docker.com/compose/install/)

```
sudo curl -L https://github.com/docker/compose/releases/download/1.19.0/docker-compose-`uname -s`-`uname -m` \
  -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo curl -L https://raw.githubusercontent.com/docker/compose/$(docker-compose version --short)/contrib/completion/bash/docker-compose \
  -o /etc/bash_completion.d/docker-compose
```

### docker machine

Installation

```
base=https://github.com/docker/machine/releases/download/v0.14.0 &&
  curl -L $base/docker-machine-$(uname -s)-$(uname -m) >/tmp/docker-machine &&
  sudo install /tmp/docker-machine /usr/local/bin/docker-machine
```

Add bash completion

```
base=https://raw.githubusercontent.com/docker/machine/v0.14.0
for i in docker-machine-prompt.bash docker-machine-wrapper.bash docker-machine.bash
do
  sudo wget "$base/contrib/completion/bash/${i}" -P /etc/bash_completion.d
done
source /etc/bash_completion.d/docker-machine-prompt.bash
```

### ports

Update iptables to reflect ports 2376 (tcp), 2377 (tcp), 7946 (tcp, udp), 4789 (udp)

```
sudo iptables -A INPUT -p tcp -m state --state NEW -m tcp --dport 2376 -j ACCEPT
sudo iptables -A INPUT -p tcp -m state --state NEW -m tcp --dport 2377 -j ACCEPT
sudo iptables -A INPUT -p tcp -m state --state NEW -m tcp --dport 7946 -j ACCEPT
sudo iptables -A INPUT -p udp -m state --state NEW -m udp --dport 7946 -j ACCEPT
sudo iptables -A INPUT -p udp -m state --state NEW -m udp --dport 4789 -j ACCEPT
sudo iptables -D INPUT -j REJECT --reject-with icmp-host-prohibited
sudo iptables -A INPUT -j REJECT --reject-with icmp-host-prohibited
```

A test of swarm and the overlay network can be performed by following this [getting started tutorial](https://docs.docker.com/get-started/).

## GlusterFS nodes

- **server**: galera-1.edc.renci.org
- **server**: galera-2.edc.renci.org

Install packages on each node

```
sudo yum -y install centos-release-gluster
sudo yum -y install glusterfs-server
sudo service glusterd start
sudo service glusterd status
```

Update iptables (allow all traffic from other gluster node - example from galera-1.edc.renci.org: 172.25.8.171 shown below)

```
sudo iptables -I INPUT -p all -s 172.25.8.172 -j ACCEPT
sudo iptables -D INPUT -j REJECT --reject-with icmp-host-prohibited
sudo iptables -A INPUT -j REJECT --reject-with icmp-host-prohibited
```

- Wound up disabling iptables on both servers while figuring out exactly which ports need to be open for communicating with the docker swarm cluster

Check peer status to ensure both nodes can see each other (example from galera-1.edc.renci.org: 172.25.8.171)

```console
$ sudo gluster peer probe galera-2.edc.renci.org
peer probe: success.
$ sudo gluster peer status
Number of Peers: 1

Hostname: galera-2.edc.renci.org
Uuid: 4fbfdd6d-5090-49d5-9595-b7bc1a7a4ec1
State: Peer in Cluster (Connected)
```

Define "bricks" and start them (from either node)

```
sudo mkdir -p /var/brick/home /var/brick/secret
sudo gluster volume create home replica 2 \
  galera-1.edc.renci.org:/var/brick/home \
  galera-2.edc.renci.org:/var/brick/home
sudo gluster volume start home
sudo gluster volume create secret replica 2 \
  galera-1.edc.renci.org:/var/brick/secret \
  galera-2.edc.renci.org:/var/brick/secret
sudo gluster volume start secret
```

View the volume info (from either node)

```console
$ sudo gluster volume info

Volume Name: home
Type: Replicate
Volume ID: 205e3667-aa2d-4264-a8f0-1902f2cc7a12
Status: Started
Snapshot Count: 0
Number of Bricks: 1 x 2 = 2
Transport-type: tcp
Bricks:
Brick1: galera-1.edc.renci.org:/var/brick/home
Brick2: galera-2.edc.renci.org:/var/brick/home
Options Reconfigured:
transport.address-family: inet
nfs.disable: on
performance.client-io-threads: off

Volume Name: secret
Type: Replicate
Volume ID: 235a1c1a-0a26-4e2b-959b-0b09116dfa83
Status: Started
Snapshot Count: 0
Number of Bricks: 1 x 2 = 2
Transport-type: tcp
Bricks:
Brick1: galera-1.edc.renci.org:/var/brick/secret
Brick2: galera-2.edc.renci.org:/var/brick/secret
Options Reconfigured:
transport.address-family: inet
nfs.disable: on
performance.client-io-threads: off
```

## Deploy the cluster

### glusterfs plugin

Install the `trajano/glusterfs-volume-plugin` on each node in the cluster: [reference](https://github.com/trajano/docker-volume-plugins)

```
docker plugin install \
  --alias glusterfs \
  trajano/glusterfs-volume-plugin \
  --grant-all-permissions \
  --disable
docker plugin set glusterfs SERVERS=172.25.8.171,172.25.8.172
docker plugin enable glusterfs
```
Sample output from one of the nodes

```console
$ docker plugin install \
>   --alias glusterfs \
>   trajano/glusterfs-volume-plugin \
>   --grant-all-permissions \
>   --disable
latest: Pulling from trajano/glusterfs-volume-plugin
1d91b8312aa5: Downloading [>                                                  ]  539.9kB/83.31MB
1d91b8312aa5: Download complete
Digest: sha256:1d60cd35ae19e5b6ea48b59db3fa82af7c3d9ea9c29eb77738682970e731773b
Status: Downloaded newer image for trajano/glusterfs-volume-plugin:latest
Installed plugin trajano/glusterfs-volume-plugin
$ docker plugin set glusterfs SERVERS=172.25.8.171,172.25.8.172
$ docker plugin enable glusterfs
glusterfs
```

### swarm

Init swarm on manager node **mjs-dev-1.edc.renci.org**

```
docker swarm init
```

Sample output

```console
$ docker swarm init
Swarm initialized: current node (utzh7jvvfhvhwd64kzuktekyu) is now a manager.

To add a worker to this swarm, run the following command:

    docker swarm join --token SWMTKN-1-26crjman36xdtvb22m6ca0wv7ztbxb15zcci2zh2uz9y1guvzi-0avrjw5vw31vunt6m9ohg5bz0 172.25.8.43:2377

To add a manager to this swarm, run 'docker swarm join-token manager' and follow the instructions.
```

Join swarm network on other nodes

```
docker swarm join \
  --token TOKEN_FROM_MANAGER \
  MANAGER_IP:2377
```

Sample output

```console
$ docker swarm join \
  --token SWMTKN-1-26crjman36xdtvb22m6ca0wv7ztbxb15zcci2zh2uz9y1guvzi-0avrjw5vw31vunt6m9ohg5bz0 \
  172.25.8.43:2377
This node joined a swarm as a worker.
```

### overlay network

Create the overlay network on the manager node **mjs-dev-1.edc.renci.org**

```
docker network create --driver=overlay --attachable slurm-net
```
Sample output

```console
$ docker network create --driver=overlay --attachable slurm-net
w5h5361kprtdti84fuuhijfrz
```

### deploy the stack

Deploy the stack from the manager node **mjs-dev-1.edc.renci.org**

```
docker stack deploy --with-registry-auth slurm --compose-file=./docker-compose.yml
```
Sample output

```console
$ docker stack deploy --with-registry-auth slurm --compose-file=./docker-compose.yml
Ignoring unsupported options: build, privileged

Ignoring deprecated options:

container_name: Setting the container name is not supported.

Creating service slurm_controller
Creating service slurm_database
Creating service slurm_worker01
Creating service slurm_worker02
Creating service slurm_visualizer
```

## Testing

At this point the nodes should all be vialbe and ready to work. Using the visulazer, determine where the **controller** node is and log into it to issue the slurm commands as described in the main [README](https://github.com/scidas/slurm-in-docker/blob/master/README.md) file.

![Slurm cluster](https://user-images.githubusercontent.com/5332509/39018939-a968faf2-43f5-11e8-8c91-d87b51fd25cb.png)

### shutting down the stack

Remove cluster from the manager node **mjs-dev-1.edc.renci.org**

```
docker stack rm slurm
```

Sample output

```console
$ docker stack rm slurm
Removing service slurm_controller
Removing service slurm_database
Removing service slurm_visualizer
Removing service slurm_worker01
Removing service slurm_worker02
```

### clean up

To clean up gluster files between runs, the output files from the previous run should be cleared from the shared GlusterFS file system

Run on all swarm nodes

```
docker volume rm home secret
```

Run on one node

```
docker volume create -d glusterfs home
docker volume create -d glusterfs secret
docker run --rm -ti -v home:/gfs-home -v secret:/gfs-secret centos:7 /bin/bash
###  rm all contents from /gfs-home and /gfs-secret
docker volume rm home secret
```

Leaving the cluster (run on each node)

```
docker swarm leave -f
```

## Reference

`docker-compose.yml` file used in testing from **mjs-dev-1.edc.renci.org**:

```yaml
version: '3.4'

services:
  controller:
    build:
      context: ./controller
      dockerfile: Dockerfile
    image: scidas/slurm.controller:19.05.1
    deploy:
      replicas: 1
      restart_policy:
        condition: on-failure
    container_name: controller
    privileged: true
    volumes:
      - gfs-home:/home
      - gfs-secret:/.secret
    #restart: always
    hostname: controller.local.dev
    networks:
      - slurm-net
    environment:
      USE_SLURMDBD: 'true'
      CLUSTER_NAME: snowflake
      CONTROL_MACHINE: controller
      SLURMCTLD_PORT: 6817
      SLURMD_PORT: 6818
      ACCOUNTING_STORAGE_HOST: database
      ACCOUNTING_STORAGE_PORT: 6819
      COMPUTE_NODES: worker01 worker02
      PARTITION_NAME: docker

  database:
    build:
      context: ./database
      dockerfile: Dockerfile
    image: scidas/slurm.database:19.05.1
    deploy:
      replicas: 1
      restart_policy:
        condition: on-failure
    depends_on:
      - controller
    container_name: database
    privileged: true
    volumes:
      - gfs-home:/home
      - gfs-secret:/.secret
    #restart: always
    hostname: database.local.dev
    networks:
      - slurm-net
    environment:
      DBD_ADDR: database
      DBD_HOST: database
      DBD_PORT: 6819
      STORAGE_HOST: database.local.dev
      STORAGE_PORT: 3306
      STORAGE_PASS: password
      STORAGE_USER: slurm

  worker01:
    build:
      context: ./worker
      dockerfile: Dockerfile
    image: scidas/slurm.worker:19.05.1
    deploy:
      replicas: 1
      restart_policy:
        condition: on-failure
    depends_on:
      - controller
    container_name: worker01
    privileged: true
    volumes:
      - gfs-home:/home
      - gfs-secret:/.secret
    #restart: always
    hostname: worker01.local.dev
    networks:
      - slurm-net
    environment:
      CONTROL_MACHINE: controller
      ACCOUNTING_STORAGE_HOST: database
      COMPUTE_NODES: worker01 worker02

  worker02:
    build:
      context: ./worker
      dockerfile: Dockerfile
    image: scidas/slurm.worker:19.05.1
    deploy:
      replicas: 1
      restart_policy:
        condition: on-failure
    depends_on:
      - controller
    container_name: worker02
    privileged: true
    volumes:
      - gfs-home:/home
      - gfs-secret:/.secret
    #restart: always
    hostname: worker02.local.dev
    networks:
      - slurm-net
    environment:
      CONTROL_MACHINE: controller
      ACCOUNTING_STORAGE_HOST: database
      COMPUTE_NODES: worker01 worker02

  visualizer:
    image: dockersamples/visualizer:stable
    ports:
      - "8080:8080"
    volumes:
      - "/var/run/docker.sock:/var/run/docker.sock"
    deploy:
      placement:
        constraints: [node.role == manager]
    networks:
      - slurm-net

volumes:
  gfs-home:
    driver: glusterfs
    name: "home"
  gfs-secret:
    driver: glusterfs
    name: "secret"

networks:
  slurm-net:
    external: true
```
