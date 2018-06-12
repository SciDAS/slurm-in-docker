# slurm-in-docker SciApp

## Docker images

**NOTE**: The following images should already be published to the [SciDAS organization](https://hub.docker.com/u/scidas/dashboard/) on docker hub.

If updates are required, the images will be expected to be found in Docker Hub and would need to be rebuilt and pushed.

Build base container and push to dockerhub

```
docker build -f Dockerfile.gfs -t scidas/slurm.base:gfs .
```

Build controller, database and worker, and push to docker hub.

```
docker-compose -f docker-compose-gfs.yml build
```

docker Images

```
$ docker images | grep scidas
scidas/slurm.worker               gfs                 1fed81b0df27        3 days ago          1.25GB
scidas/slurm.database             gfs                 f56376e5b362        3 days ago          819MB
scidas/slurm.controller           gfs                 66a77c96dcf8        3 days ago          1.25GB
scidas/slurm.base                 gfs                 1193c1b3bf97        3 days ago          799MB
```

## Deploy

### POST appliance specification file

```
curl -X POST -d @slurm-gfs.json http://XXX.XXX.XXX.XXX:XXXX/appliance
```

**NOTE**: The provided example specification file does NOT provide GlusterFS servers. These must be configured by the user and be running prior to launching the appliance. See the reference at the bottom of the page.

### Dashboards

- DC/OS dashboard

<img width="80%" alt="DC/OS dashboard" src="https://user-images.githubusercontent.com/5332509/41315257-f86a0fec-6e5c-11e8-8ee6-fbfd2758f925.png">

- Appliance status:

<img width="80%" alt="Appliance Status" src="https://user-images.githubusercontent.com/5332509/41315220-dc7b45a8-6e5c-11e8-9996-f70941cc28a4.png">

### Shared volumes

- **secret**: set up and configuration between nodes as `/.secret`
- **home**: shared home directory as `/home`
- **modules**: Lmod modules as `/opt/app/Linux`
- **modulefiles**: Lmod Lua scripts as `/opt/app/modulefiles/Linux`

### SSH access

From the perspective of the included [gfs-client](gfs-client) code, the generated SSH key pairs can be found at the following locations.

user `root`:

- id_rsa: `/brick/secret/root_ssh_controller/id_rsa`
- id_rsa.pub: `/brick/secret/root_ssh_controller/id_rsa.pub`

Example:

```console
# cat /brick/secret/root_ssh_controller/id_rsa
-----BEGIN RSA PRIVATE KEY-----
MIIEogIBAAKCAQEA+XeMQZAofSI1lAb7WI7Xk0KFCctJlkouv5Nfg0r99HEnpopN
/7nJWzE2mXfFflLHrhTnALin7mTIW4mZfnL5hSYVyum/GDsAwgKGQl+HCxAL2vf3
QK2DWTWVq/J7vhQ6Icz6LRswctvIU+ed5f+sqY/Jd8bRS0LOVLUUL+wlSoxEsq4J
IjOsPhF9j7LYookmu2dWemQQM8d23TdzsVCbpUQf7zgrEBanBVfUaZXo7D1WdQd6
l6w32PlACvm/bypJ7cchI3kDeqRJrnN1Xg8vmuxcX5NYnUTmLLZWezYkCfnNhOKc
+9axWEAGhCGMLcOsJo5a8A1bqJStDYeGs7VHsQIDAQABAoIBAG6lw6Pg2NSHs9Pw
NNNWp+889d0eOYlbZdi6+QY24OTmu3t2pJnkQZcdAOaY5RPei4p+4ubDAFkQgn13
TolzXZDdD5Vsj8GjifaDQCF4VWFmwJtimFwrmbKbvcMCTjhEqHQNgnk3Mgn/yZ7N
gI9fE6oxiF6D5JjJDNMtbcLDrtac+D1Q47uKp9GNuAaPA57J0Y/DDOmd5ybm2mFm
59IR6zBYHdIO0gXpevO+GxzxBiSpEKrDYkXrgvEx4oF9ubEXMVbrd7pFm+GFrnt6
IhzIIXPEI9lV9Jimn9g3s+43D3YEoQU+lGy4eZPYfi8iXni0PPTi55anyB3NNbfn
sfLmEAECgYEA/gJLh1oNN/O657tVJT5TfSmTl9BalKMfklgTnkWnMBRJ21ZTSBNU
1jFLIAf8AsFsifVWhujBM2CobEPB/K1VFkLN14fDT+zLKWhNBHUXfH2KGbkg9jGc
rDXZw9KVzy3bmcFH34KFRg2YkkOIxg73T6n0OQ1F0UQzpjyyId//KHECgYEA+2wj
grGnZLfG+6umtWs1D3g2Dzljn6qZ3FhRp3mYvxJFAI2mmnJsEFVKeAtlzimN7MTX
w4P1rxJb/0E1nnumwBEpj7s6EXqZnEP16x/nMYNInjGvqejvEKcBGk3IZ+iWemoY
It2RembIaM59PzTKsOHrFN+CQilKWByPjl91s0ECgYAr3M+YFufTcqYi4AmK/eFC
6swO2i7aHfUUu1rf6N0/AzHhy11kQ9pRhn+Xj2loPGh2xkPj1guOyLEsyOKVtITN
7ElJX6tNgPFwPA+YpnOgzrjrSjmz6ctJPZ9WHmY6OYwDWAoGQa6r8ysWjszujqUM
P6fpti4JPgLBQRftm5WfMQKBgA1uWHNJ5ERYIPQe1lgIsxvxcwnbKfxEk9WWjj4h
G8zRQAhoiMblZ+pzc/f3u+eIhsFoPpJ+QSiqFWoMZL3joyPNhufbu51lbEFRzBhU
avhVKBLzWov8GpFMKp3qG9OZNDiz5Dgwl+3vAbO/nCc9Pbq3RuSlkALSy9rrI6wa
Y2JBAoGAGfwAcC4Dl/3wyq3BztHGwCeCEEiD1TWqTZowDdRvpX8Pm1p+OmCHaJYV
pjm9OSC9dvaqp0FLjbQXZyUYUMjfUvebp0+q0VFdrkK3HUhEnI861aPBGl3l58dy
eJN5pESkg5Es2IVx7mrqrQ0dGXBQaUx5OhN/9GupfHxdULJBrr8=
-----END RSA PRIVATE KEY-----
# cat /brick/secret/root_ssh_controller/id_rsa.pub
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQD5d4xBkCh9IjWUBvtYjteTQoUJy0mWSi6/k1+DSv30cSemik3/uclbMTaZd8V+UseuFOcAuKfuZMhbiZl+cvmFJhXK6b8YOwDCAoZCX4cLEAva9/dArYNZNZWr8nu+FDohzPotGzBy28hT553l/6ypj8l3xtFLQs5UtRQv7CVKjESyrgkiM6w+EX2PstiiiSa7Z1Z6ZBAzx3bdN3OxUJulRB/vOCsQFqcFV9RplejsPVZ1B3qXrDfY+UAK+b9vKkntxyEjeQN6pEmuc3VeDy+a7Fxfk1idROYstlZ7NiQJ+c2E4pz71rFYQAaEIYwtw6wmjlrwDVuolK0Nh4aztUex root@619a8953005f-2018-06-12
```

use `worker`:

- id_rsa: `/brick/home/worker/.ssh/id_rsa`
- id_rsa.pub: `/brick/home/worker/.ssh/id_rsa.pub`

Example:

```console
# cat /brick/home/worker/.ssh/id_rsa
-----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEAq8oAD6iLYFx0a1hK8a8DYjV1/F1PwPwFnp4GWpfk0IOY769U
BaJWX8LM6kejvd59ZCgrh1te0YaR1GvwKjJntPjfBXFsksaEZBd35rztlifx+cGy
r3sLnC7MfCsLq8/assSSBbC8eMram88G2IUcorFdDMJn/rjp3kGjdfT477twrUL5
mce3A7l1znzj/Uq/eROt1+HA7TlKh20mOylvPH6vDFShSQ5Q79rQjFzxRjaTNCfW
srCj0HPmm6gKuXWddrxRToSJgFFK/rZOlMMNqN+TPkA1ZdBQKEzVCwXNSMv/oact
ZR7QYyuew5D2avUwOT+Iv8XIyGeZO/wWFN0qJwIDAQABAoIBAHiorbhRymtJJOAM
qL7uDPNa118E7zJ+EThih9Xzn9wwwid/PwWiCwbBnQnkfYarkejaKhCtRYDnAuBv
W8VXl+3Na1+4VekVlAF1VlrzUfDIZ7XjrayBQRtW53tDBLSNjm9Hj8R9aTNyT29m
TsmfXQiMiO2gUkjf+iuIcNY11O8T0ljXf6Os5ttL8ZL8rjC+5gwm340dyhhDGxXA
16WFqEeh2iDdNXxHd07Be2LlYTVVmGYMWKdJPX9Psktx1Y86orPkRuK42ozAGr9Z
nBY19wQiEq1vgaggI7fN4PufNx60sD1EMPGTAa2Njpu0e+gC2YfKFyosHuvHnGx1
GtfNmdkCgYEA2+/UtEv72iRS2wdbVhYH30emj2lXwZjp1ZPhWD1P/zgXjNp7VfjD
DEIzIT857uxsAMRMbAh/pUUY2SSroUSkzXWpym8Yay5ecPsHOuXHFBgENVPyrhZY
JlFBpMO6GOZmVWym1wQ/m7be7gBtdBLd4TzZnmM2a0ZVgyutPz1v/lsCgYEAx/UY
qni7wmYiUlQ39HXF/RFkgukyA4W76ij8lsq/t4T3dH1G8p9HPQ7SFD1pBDF0fjqB
4O/jaE8vYAB0I6SQu9Aoy9RUIshZQ2hC1k7jKfSlVpaErl7keVMpSGsFgO4aMMLw
UbgdbRMJCMg88aSeRAVN21gZH1H+jZzX5mRS5SUCgYEAmxLaVhnxRVkxNpBUXTmB
aXR6w0mSf8WSsm3niLEKc7iYGk9+gRq6ZC1VIc8TyRvX9x5xiAbiAaTbpVeO0FG3
Jcsd4cc9X209V8oXyfZzzP42EWfUh9znYHUQpN0AnUfuxbKrXJX5R5DEVOnmQt5+
pa6i/mOT3kWkS62DJUDrc1sCgYBiga5bHQtyo5o48OB4ACU/nPflPjizX4jJvNNi
/hMgt9KogqcXE7ymqcx4yCAaPrrjDLO7OrLPSmNOairM/F+JBu1yLPIeCJFhEdYL
eeWTX8CsPY6z0G/CDWQDFyYo9CPW7dIyj/9/IqeKugq8CJsna22Fp4sI0P4UibYa
/EWSOQKBgBDLgBT54iyF8H5l34Tqd4j6TTt9SV6F0KzAM6nC07EKpiuxtN4MlnTX
57BBVkldjBgzWRiXTkqOeWccOzUkvsqTpRfIbOwk6DHxVeQfmHMU84OLsVfxWaFa
k9sCYaTpnpHXLB0p6JUVBxoBZdJxcL8AMqdj9+o1gg3uA8JHNdzN
-----END RSA PRIVATE KEY-----
# cat /brick/home/worker/.ssh/id_rsa.pub
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCrygAPqItgXHRrWErxrwNiNXX8XU/A/AWengZal+TQg5jvr1QFolZfwszqR6O93n1kKCuHW17RhpHUa/AqMme0+N8FcWySxoRkF3fmvO2WJ/H5wbKvewucLsx8Kwurz9qyxJIFsLx4ytqbzwbYhRyisV0Mwmf+uOneQaN19Pjvu3CtQvmZx7cDuXXOfOP9Sr95E63X4cDtOUqHbSY7KW88fq8MVKFJDlDv2tCMXPFGNpM0J9aysKPQc+abqAq5dZ12vFFOhImAUUr+tk6Uww2o35M+QDVl0FAoTNULBc1Iy/+hpy1lHtBjK57DkPZq9TA5P4i/xcjIZ5k7/BYU3Son worker@619a8953005f-2018-06-12
```

The keys can be copied and used to access the `controller` node as either the `root` or `worker` user.

Example as `root` user:

The contents of `root`'s id_rsa and id_rsa.pub files were copied to files named root_id_rsa and root_id_rsa.pub.

Use the IP and Port as observed in the Appliance Status to SSH onto the controller node.

```console
$ ssh -i ./root_id_rsa -p 20022 root@129.114.109.33
The authenticity of host '[129.114.109.33]:20022 ([129.114.109.33]:20022)' can't be established.
RSA key fingerprint is SHA256:hSgY9ZKzuwAa7AUkK3bs1+fAn5sbpdMc/TuuYxvHCrI.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added '[129.114.109.33]:20022' (RSA) to the list of known hosts.
[root@619a8953005f ~]#
```

### Update `/etc/hosts`

There is a inotify task that will update the `/etc/hosts` file of the node any time a file named `/.secret/etc_hosts` is read or written to. This file needs to be read by all nodes in order to trigger the update, and this can be invoked by using the `cat` command on the controller and `srun` command for the workers.

On controller using `cat`:

```console
# cat /etc/hosts
127.0.0.1	localhost
::1	localhost ip6-localhost ip6-loopback
fe00::0	ip6-localnet
ff00::0	ip6-mcastprefix
ff02::1	ip6-allnodes
ff02::2	ip6-allrouters
9.0.2.130	619a8953005f controller-slurm-gfs.marathon.containerip.dcos.thisdcos.directory controller
9.0.4.130	09e3685b7f74 db-slurm-gfs.marathon.containerip.dcos.thisdcos.directory db
# cat /.secret/etc_hosts
9.0.2.130	619a8953005f controller-slurm-gfs.marathon.containerip.dcos.thisdcos.directory controller
9.0.4.130	09e3685b7f74 db-slurm-gfs.marathon.containerip.dcos.thisdcos.directory db
9.0.1.130	c2edbe8e92eb worker02-slurm-gfs.marathon.containerip.dcos.thisdcos.directory worker02
9.0.5.130	00d5a860e09b worker01-slurm-gfs.marathon.containerip.dcos.thisdcos.directory worker01
# cat /etc/hosts
127.0.0.1	localhost
::1	localhost ip6-localhost ip6-loopback
fe00::0	ip6-localnet
ff00::0	ip6-mcastprefix
ff02::1	ip6-allnodes
ff02::2	ip6-allrouters
9.0.2.130	619a8953005f controller-slurm-gfs.marathon.containerip.dcos.thisdcos.directory controller
9.0.4.130	09e3685b7f74 db-slurm-gfs.marathon.containerip.dcos.thisdcos.directory db
9.0.1.130	c2edbe8e92eb worker02-slurm-gfs.marathon.containerip.dcos.thisdcos.directory worker02
9.0.5.130	00d5a860e09b worker01-slurm-gfs.marathon.containerip.dcos.thisdcos.directory worker01
```

On workers using `srun`:

```console
# srun -N 2 cat /etc/hosts
127.0.0.1	localhost
::1	localhost ip6-localhost ip6-loopback
fe00::0	ip6-localnet
ff00::0	ip6-mcastprefix
ff02::1	ip6-allnodes
ff02::2	ip6-allrouters
9.0.5.130	00d5a860e09b worker01-slurm-gfs.marathon.containerip.dcos.thisdcos.directory worker01
9.0.2.130	619a8953005f controller-slurm-gfs.marathon.containerip.dcos.thisdcos.directory controller
9.0.4.130	09e3685b7f74 db-slurm-gfs.marathon.containerip.dcos.thisdcos.directory db
9.0.1.130	c2edbe8e92eb worker02-slurm-gfs.marathon.containerip.dcos.thisdcos.directory worker02
127.0.0.1	localhost
::1	localhost ip6-localhost ip6-loopback
fe00::0	ip6-localnet
ff00::0	ip6-mcastprefix
ff02::1	ip6-allnodes
ff02::2	ip6-allrouters
9.0.1.130	c2edbe8e92eb worker02-slurm-gfs.marathon.containerip.dcos.thisdcos.directory worker02
9.0.2.130	619a8953005f controller-slurm-gfs.marathon.containerip.dcos.thisdcos.directory controller
9.0.4.130	09e3685b7f74 db-slurm-gfs.marathon.containerip.dcos.thisdcos.directory db
# srun -N 2 cat /.secret/etc_hosts
9.0.2.130	619a8953005f controller-slurm-gfs.marathon.containerip.dcos.thisdcos.directory controller
9.0.4.130	09e3685b7f74 db-slurm-gfs.marathon.containerip.dcos.thisdcos.directory db
9.0.1.130	c2edbe8e92eb worker02-slurm-gfs.marathon.containerip.dcos.thisdcos.directory worker02
9.0.5.130	00d5a860e09b worker01-slurm-gfs.marathon.containerip.dcos.thisdcos.directory worker01
9.0.2.130	619a8953005f controller-slurm-gfs.marathon.containerip.dcos.thisdcos.directory controller
9.0.4.130	09e3685b7f74 db-slurm-gfs.marathon.containerip.dcos.thisdcos.directory db
9.0.1.130	c2edbe8e92eb worker02-slurm-gfs.marathon.containerip.dcos.thisdcos.directory worker02
9.0.5.130	00d5a860e09b worker01-slurm-gfs.marathon.containerip.dcos.thisdcos.directory worker01
# srun -N 2 cat /etc/hosts
127.0.0.1	localhost
::1	localhost ip6-localhost ip6-loopback
fe00::0	ip6-localnet
ff00::0	ip6-mcastprefix
ff02::1	ip6-allnodes
ff02::2	ip6-allrouters
9.0.5.130	00d5a860e09b worker01-slurm-gfs.marathon.containerip.dcos.thisdcos.directory worker01
9.0.2.130	619a8953005f controller-slurm-gfs.marathon.containerip.dcos.thisdcos.directory controller
9.0.4.130	09e3685b7f74 db-slurm-gfs.marathon.containerip.dcos.thisdcos.directory db
9.0.1.130	c2edbe8e92eb worker02-slurm-gfs.marathon.containerip.dcos.thisdcos.directory worker02
127.0.0.1	localhost
::1	localhost ip6-localhost ip6-loopback
fe00::0	ip6-localnet
ff00::0	ip6-mcastprefix
ff02::1	ip6-allnodes
ff02::2	ip6-allrouters
9.0.1.130	c2edbe8e92eb worker02-slurm-gfs.marathon.containerip.dcos.thisdcos.directory worker02
9.0.2.130	619a8953005f controller-slurm-gfs.marathon.containerip.dcos.thisdcos.directory controller
9.0.4.130	09e3685b7f74 db-slurm-gfs.marathon.containerip.dcos.thisdcos.directory db
9.0.5.130	00d5a860e09b worker01-slurm-gfs.marathon.containerip.dcos.thisdcos.directory worker01
```

### Lmod

Build/copy the desired Lmod modules from [https://github.com/SciDAS/lmod-modules-centos](https://github.com/SciDAS/lmod-modules-centos) to the appropriate shared `modules` and `modulefiles` directories.

## Tear down

The appliance can be torn down and rebuilt using the same SSH keys as needed so long as the underlying shared volumes are not altered between deployments.

This allows the user to scale the number of worker nodes or alter their configuration between runs without having to update SSH key pairs.

### DELETE appliance

```
curl -X DELETE http://XXX.XXX.XXX.XXX:XXXX/appliance/slurm-gfs
```

## Reference

### slurm-gfs.json

The example appliance definiation does not specify valid GlusterFS servers. The GlusterFS servers must be configured by the user and be running prior to launching the appliance.

```json
{
  "id": "slurm-gfs",
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
      "image": "scidas/slurm.controller:gfs",
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
        "COMPUTE_NODES": "@worker01 @worker02",
        "PARTITION_NAME": "docker",
        "GFS_SERVERS": "YOUR_GFS_SERVER", ;;; <-- THIS
        "GFS_SERVER_DIRS": "/brick/home:/brick/secret:/brick/modules:/brick/modulefiles",
        "GFS_CLIENT_DIRS": "/home:/.secret:/opt/apps/Linux:/opt/apps/modulefiles/Linux"
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
      "image": "scidas/slurm.database:gfs",
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
        "GFS_SERVERS": "YOUR_GFS_SERVER", ;;; <-- THIS
        "GFS_SERVER_DIRS": "/brick/home:/brick/secret",
        "GFS_CLIENT_DIRS": "/home:/.secret"
      },
      "force_pull_image": true
    },
    {
      "id": "worker01",
      "dependencies": [
        "controller"
      ],
      "type": "service",
      "resources":
      {
        "cpus": 1,
        "mem": 4096,
        "disk": 8192
      },
      "network_mode": "container",
      "image": "scidas/slurm.worker:gfs",
      "is_privileged": true,
      "env":
      {
        "NODE_NAME": "@worker01 worker01",
        "CONTROL_MACHINE":"@controller",
        "ACCOUNTING_STORAGE_HOST": "@db",
        "COMPUTE_NODES": "@worker01 @worker02",
        "GFS_SERVERS": "YOUR_GFS_SERVER", ;;; <-- THIS
        "GFS_SERVER_DIRS": "/brick/home:/brick/secret:/brick/modules:/brick/modulefiles",
        "GFS_CLIENT_DIRS": "/home:/.secret:/opt/apps/Linux:/opt/apps/modulefiles/Linux"
      },
      "force_pull_image": true
    },
    {
      "id": "worker02",
      "dependencies": [
        "controller"
      ],
      "type": "service",
      "resources":
      {
        "cpus": 1,
        "mem": 4096,
        "disk": 8192
      },
      "network_mode": "container",
      "image": "scidas/slurm.worker:gfs",
      "is_privileged": true,
      "env":
      {
        "NODE_NAME": "@worker02 worker02",
        "CONTROL_MACHINE":"@controller",
        "ACCOUNTING_STORAGE_HOST": "@db",
        "COMPUTE_NODES": "@worker01 @worker02",
        "GFS_SERVERS": "YOUR_GFS_SERVER", ;;; <-- AND THIS
        "GFS_SERVER_DIRS": "/brick/home:/brick/secret:/brick/modules:/brick/modulefiles",
        "GFS_CLIENT_DIRS": "/home:/.secret:/opt/apps/Linux:/opt/apps/modulefiles/Linux"
      },
      "force_pull_image": true
    }
  ]
}
```

### gfs-client/docker-compose.yml

The included gfs-client definition can be used to observe/interact with the shared GlusterFS volumes that the appliance is using. It must also have its `GFS_SERVERS` value defined prior to use.

```yaml
version: '3.0'
services:

  client:
    build:
      context: ./
      dockerfile: Dockerfile
    image: client
    container_name: client
    privileged: true
    hostname: client.gfs.local
    environment:
      GFS_SERVERS: 'YOUR_GFS_SERVER' # <-- THIS
      GFS_SERVER_DIRS: '/brick/home:/brick/secret:/brick/modules:/brick/modulefiles'
      GFS_CLIENT_DIRS: '/brick/home:/brick/secret:/brick/modules:/brick/modulefiles'
```
