# Slurm in Docker

**WORK IN PROGRESS**

Use [Docker](https://www.docker.com/) to explore the various components of [Slurm](https://www.schedmd.com/index.php)

## Contents

1. [packages](packages) - Build the RPM packages for running Slurm on CentOS 7
2. [head-node](head-node) - Build/Use a Slurm head node based on CentOS 7
3. [compute-node](compute-node) - Build/Use Slurm compute node(s) based on CentOS 7

## References

Slurm workload manager: [https://www.schedmd.com/index.php](https://www.schedmd.com/index.php)

- Slurm is a highly configurable open-source workload manager. In its simplest configuration, it can be installed and configured in a few minutes (see [Caos NSA and Perceus: All-in-one Cluster Software Stack](http://www.linux-mag.com/id/7239/1/) by Jeffrey B. Layton). Use of optional plugins provides the functionality needed to satisfy the needs of demanding HPC centers. More complex configurations rely upon a database for archiving accounting records, managing resource limits by user or bank account, and supporting sophisticated scheduling algorithms.

Docker: [https://www.docker.com](https://www.docker.com)

- Docker is the company driving the container movement and the only container platform provider to address every application across the hybrid cloud. Today’s businesses are under pressure to digitally transform but are constrained by existing applications and infrastructure while rationalizing an increasingly diverse portfolio of clouds, datacenters and application architectures. Docker enables true independence between applications and infrastructure and developers and IT ops to unlock their potential and creates a model for better collaboration and innovation.
