# NFS v3 Server

## About

Volumes served by the NFS server can be defined as host volume mounts, or reside strictly inside the docker container. Volumes are mounted at runtime based on environment variables passed into the container.

## Environment variables

### Server side

### `RPCNFSDCOUNT`

nfsd threads - number of nfsd threads to use. Default `=8`.

### `NFS_SERVER_DIRS`

NSF mounts - full path for server side NFS volumes, as seen by the container, that will be serviced. Default `='/nfs/share'`. All volumes should begin with `/nfs` and a semicolon (`:`) should be used between each path definition.

### Client side

### `NFS_SERVER`

FQDN or IP - of the NFS server. Default `=server`.

### `NFS_SERVER_DIRS`

Volumes as provided from the NFS server. Default `='/nfs/share'`.

### `NFS_CLIENT_DIRS`

Volumes to mount on the client. Default `='/mnt/share'`. Must be an in order correlation to the volumes as defined in `NFS_SERVER_DIRS` as that is the order they will be mounted in. Example: `mount ${NFS_SERVER}:${NFS_SERVER_DIRS[0]} ${NFS_CLIENT_DIRS[0]}`

## Preliminary setup

### docker volume

Due to differences in permissions in how macOS and Linux treat host mounted volumes, a docker volume will be defined for use by the primary NFS export directory, and bound to the server container.

### Linux

Create directory named **nfs** and create a docker volume with it:

```
mkdir nfs
docker volume create \
  --name nfs-vol \
  --opt type=tmpfs \
  --opt device=$(pwd)/nfs \
  --opt o=bind
```

Verify creation of volume:

```console
$ docker volume inspect nfs-vol
[
    {
        "CreatedAt": "2018-05-19T16:18:31-04:00",
        "Driver": "local",
        "Labels": {},
        "Mountpoint": "/var/lib/docker/volumes/nfs-vol/_data",
        "Name": "nfs-vol",
        "Options": {
            "device": "/home/stealey/slurm-in-docker/nfs",
            "o": "bind",
            "type": "tmpfs"
        },
        "Scope": "local"
    }
]
```

Viewing the contents of the volume: Since the Linux volume is bound to the host, we can simply observe the contents using `ls`.

```
ls -lR nfs
```

### macOS

Create docker volume named **nfs**:

```
docker volume create \
  --name nfs-vol \
  --driver local \
  --opt type=tmpfs \
  --opt device=tmpfs
```

Verify creation of volume:

```console
$ docker volume inspect nfs-vol
[
    {
        "CreatedAt": "2018-05-19T12:27:54Z",
        "Driver": "local",
        "Labels": {},
        "Mountpoint": "/var/lib/docker/volumes/nfs-vol/_data",
        "Name": "nfs-vol",
        "Options": {
            "device": "tmpfs",
            "type": "tmpfs"
        },
        "Scope": "local"
    }
]
```

Viewing the contents of the volume: Run this from your Mac terminal and it'll drop you in a container with full permissions on the Moby VM. This also works for Docker for Windows for getting in Moby Linux VM (doesn't work for Windows Containers).

```
docker run -it --rm --privileged --pid=host justincormack/nsenter1
```

List docker's volumes

```
ls /var/lib/docker/volumes
```

more info: [https://github.com/justincormack/nsenter1](https://github.com/justincormack/nsenter1)
