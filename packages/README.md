# Slurm Package Builder

Builds the [Slurm](https://www.schedmd.com/index.php) packages from their [latest stable versions](https://www.schedmd.com/downloads.php) based on the environment variable named `SLURM_VERSION` (default is `SLURM_VERSION=17.11.5`)

Supported builds (defaults shown):

- CentOS 7 
	- `slurm-17.11.5-1.el7.centos.x86_64.rpm`
	- `slurm-contribs-17.11.5-1.el7.centos.x86_64.rpm`
	- `slurm-devel-17.11.5-1.el7.centos.x86_64.rpm`
	- `slurm-example-configs-17.11.5-1.el7.centos.x86_64.rpm`
	- `slurm-libpmi-17.11.5-1.el7.centos.x86_64.rpm`
	- `slurm-openlava-17.11.5-1.el7.centos.x86_64.rpm`
	- `slurm-pam_slurm-17.11.5-1.el7.centos.x86_64.rpm`
	- `slurm-perlapi-17.11.5-1.el7.centos.x86_64.rpm`
	- `slurm-slurmctld-17.11.5-1.el7.centos.x86_64.rpm`
	- `slurm-slurmd-17.11.5-1.el7.centos.x86_64.rpm`
	- `slurm-slurmdbd-17.11.5-1.el7.centos.x86_64.rpm`
	- `slurm-torque-17.11.5-1.el7.centos.x86_64.rpm`

## CentOS 7

Builds the Slurm RPMs from source for CentOS 7 using Docker [centos:7](https://hub.docker.com/_/centos/) image

### Build the image

Build the docker image

```
$ cd centos-7/
$ docker build -t mjstealey/slurm.rpms:17.11.5 .
```

### Run the image 

- Specify the version of Slurm you wish to build as the environment variable `SLURM_VERSION` (default is `SLURM_VERSION=17.11.5`).
- Specify the volume to which you'd like to save the resultant rpm files (maps to `/packages` of the container).


**Generate RPMs**:

```
$ docker run --rm \
	-e SLURM_VERSION=17.11.5 \
	-v $(pwd)/rpms:/packages \
	mjstealey/slurm.rpms:17.11.5
```

**Verify RPMs**:

```console
$ ls -alh $(pwd)/rpms
-rw-r--r--   1 xxxxx  xxxxx    13M Apr  6 10:10 slurm-17.11.5-1.el7.centos.x86_64.rpm
-rw-r--r--   1 xxxxx  xxxxx    16K Apr  6 10:10 slurm-contribs-17.11.5-1.el7.centos.x86_64.rpm
-rw-r--r--   1 xxxxx  xxxxx    77K Apr  6 10:10 slurm-devel-17.11.5-1.el7.centos.x86_64.rpm
-rw-r--r--   1 xxxxx  xxxxx   5.7K Apr  6 10:10 slurm-example-configs-17.11.5-1.el7.centos.x86_64.rpm
-rw-r--r--   1 xxxxx  xxxxx   136K Apr  6 10:10 slurm-libpmi-17.11.5-1.el7.centos.x86_64.rpm
-rw-r--r--   1 xxxxx  xxxxx   8.3K Apr  6 10:10 slurm-openlava-17.11.5-1.el7.centos.x86_64.rpm
-rw-r--r--   1 xxxxx  xxxxx   139K Apr  6 10:10 slurm-pam_slurm-17.11.5-1.el7.centos.x86_64.rpm
-rw-r--r--   1 xxxxx  xxxxx   798K Apr  6 10:10 slurm-perlapi-17.11.5-1.el7.centos.x86_64.rpm
-rw-r--r--   1 xxxxx  xxxxx   1.1M Apr  6 10:10 slurm-slurmctld-17.11.5-1.el7.centos.x86_64.rpm
-rw-r--r--   1 xxxxx  xxxxx   616K Apr  6 10:10 slurm-slurmd-17.11.5-1.el7.centos.x86_64.rpm
-rw-r--r--   1 xxxxx  xxxxx   637K Apr  6 10:10 slurm-slurmdbd-17.11.5-1.el7.centos.x86_64.rpm
-rw-r--r--   1 xxxxx  xxxxx   113K Apr  6 10:10 slurm-torque-17.11.5-1.el7.centos.x86_64.rpm
```
