#!/usr/bin/env bash
set -e

wget https://download.schedmd.com/slurm/slurm-${SLURM_VERSION}.tar.bz2
rpmbuild -ta slurm-${SLURM_VERSION}.tar.bz2
cp /root/rpmbuild/RPMS/x86_64/slurm-* /packages

exec "$@"
