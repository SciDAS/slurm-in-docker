# Slurm Package Builder

Builds the [Slurm](https://www.schedmd.com/index.php) packages from their [latest stable versions](https://www.schedmd.com/downloads.php) based on the environment variable named `SLURM_VERSION` (default is `SLURM_VERSION=19.05.1`)

Supported builds (defaults shown):

- CentOS 7 - Slurm
	- `slurm-19.05.1-1.el7.centos.x86_64.rpm`
	- `slurm-contribs-19.05.1-1.el7.centos.x86_64.rpm`
	- `slurm-devel-19.05.1-1.el7.centos.x86_64.rpm`
	- `slurm-example-configs-19.05.1-1.el7.centos.x86_64.rpm`
	- `slurm-libpmi-19.05.1-1.el7.centos.x86_64.rpm`
	- `slurm-openlava-19.05.1-1.el7.centos.x86_64.rpm`
	- `slurm-pam_slurm-19.05.1-1.el7.centos.x86_64.rpm`
	- `slurm-perlapi-19.05.1-1.el7.centos.x86_64.rpm`
	- `slurm-slurmctld-19.05.1-1.el7.centos.x86_64.rpm`
	- `slurm-slurmd-19.05.1-1.el7.centos.x86_64.rpm`
	- `slurm-slurmdbd-19.05.1-1.el7.centos.x86_64.rpm`
	- `slurm-torque-19.05.1-1.el7.centos.x86_64.rpm` (conflicts with openmpi installation)
- CentOS 7 - OpenMPI 3.0.1
    - `openmpi-3.0.1-1.el7.centos.x86_64.rpm` 
      - **Note**: Installation of this rpm conflicts with `/usr/bin/mpiexec` from `slurm-torque` and as such the `slurm-torque` rpm is not installed in the **slurm-base** docker image.

## CentOS 7

Builds the Slurm RPMs from source for CentOS 7 using Docker [centos:7](https://hub.docker.com/_/centos/) image

### Build the image

Build the docker image

```
$ cd centos-7/
$ docker build -t scidas/slurm.rpms:19.05.1 .
```

### Run the image 

- Specify the version of Slurm you wish to build as the environment variable `SLURM_VERSION` (default is `SLURM_VERSION=19.05.1`).
- Specify the volume to which you'd like to save the resultant rpm files (maps to `/packages` of the container).


**Generate RPMs**:

```
$ docker run --rm \
	-e SLURM_VERSION=19.05.1 \
	-v $(pwd)/rpms:/packages \
	scidas/slurm.rpms:19.05.1
```

**Verify RPMs**:

```console
$ ls -alh $(pwd)/rpms
-rw-r--r--   1 xxxxx  xxxxx    11M Apr 12 22:39 openmpi-3.0.1-1.el7.centos.x86_64.rpm
-rw-r--r--   1 xxxxx  xxxxx    13M Apr 12 22:31 slurm-19.05.1-1.el7.centos.x86_64.rpm
-rw-r--r--   1 xxxxx  xxxxx    16K Apr 12 22:31 slurm-contribs-19.05.1-1.el7.centos.x86_64.rpm
-rw-r--r--   1 xxxxx  xxxxx    77K Apr 12 22:31 slurm-devel-19.05.1-1.el7.centos.x86_64.rpm
-rw-r--r--   1 xxxxx  xxxxx   5.7K Apr 12 22:31 slurm-example-configs-19.05.1-1.el7.centos.x86_64.rpm
-rw-r--r--   1 xxxxx  xxxxx   136K Apr 12 22:31 slurm-libpmi-19.05.1-1.el7.centos.x86_64.rpm
-rw-r--r--   1 xxxxx  xxxxx   8.3K Apr 12 22:31 slurm-openlava-19.05.1-1.el7.centos.x86_64.rpm
-rw-r--r--   1 xxxxx  xxxxx   139K Apr 12 22:31 slurm-pam_slurm-19.05.1-1.el7.centos.x86_64.rpm
-rw-r--r--   1 xxxxx  xxxxx   798K Apr 12 22:31 slurm-perlapi-19.05.1-1.el7.centos.x86_64.rpm
-rw-r--r--   1 xxxxx  xxxxx   1.1M Apr 12 22:31 slurm-slurmctld-19.05.1-1.el7.centos.x86_64.rpm
-rw-r--r--   1 xxxxx  xxxxx   616K Apr 12 22:31 slurm-slurmd-19.05.1-1.el7.centos.x86_64.rpm
-rw-r--r--   1 xxxxx  xxxxx   637K Apr 12 22:31 slurm-slurmdbd-19.05.1-1.el7.centos.x86_64.rpm
-rw-r--r--   1 xxxxx  xxxxx   113K Apr 12 22:31 slurm-torque-19.05.1-1.el7.centos.x86_64.rpm```
