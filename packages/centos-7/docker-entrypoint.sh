#!/usr/bin/env bash
set -e

# build slurm rpms
wget https://download.schedmd.com/slurm/slurm-${SLURM_VERSION}.tar.bz2
rpmbuild -ta "slurm-${SLURM_VERSION}.tar.bz2"
cp /root/rpmbuild/RPMS/x86_64/slurm-* /packages

# build openmpi rpm
wget https://www.open-mpi.org/software/ompi/v3.0/downloads/openmpi-3.0.1.tar.gz
curl https://raw.githubusercontent.com/open-mpi/ompi/v3.0.x/contrib/dist/linux/buildrpm.sh -o buildrpm.sh
chmod +x buildrpm.sh
yum -y localinstall /root/rpmbuild/RPMS/x86_64/slurm-*
mkdir -p /usr/src/redhat
cd /usr/src/redhat
ln -s /root/rpmbuild/SOURCES SOURCES
ln -s /root/rpmbuild/RPMS RPMS
ln -s /root/rpmbuild/SRPMS SRPMS
ln -s /root/rpmbuild/SPECS SPECS
cd -
./buildrpm.sh -b -s -c --with-slurm -c --with-pmi openmpi-3.0.1.tar.gz
cp /root/rpmbuild/RPMS/x86_64/openmpi-* /packages

exec "$@"
