FROM mjstealey/slurm.base:17.11.5
MAINTAINER Michael J. Stealey <stealey@renci.org>

# install openmpi 3.0.1
RUN yum -y install \
  gcc-c++ \
  gcc-gfortran \
  && yum -y localinstall \
  /packages/openmpi-*.rpm

ENV USE_SLURMDBD=true \
  CLUSTER_NAME=snowflake \
  CONTROL_MACHINE=controller \
  SLURMCTLD_PORT=6817 \
  SLURMD_PORT=6818 \
  ACCOUNTING_STORAGE_HOST=database \
  ACCOUNTING_STORAGE_PORT=6819 \
  PARTITION_NAME=docker

### Uncomment when development is complete ###
# RUN rm -f /packages/slurm-*.rpm /packages/openmpi-*.rpm \
#   && yum clean all \
#   && rm -rf /var/cache/yum

COPY docker-entrypoint.sh /docker-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/tini", "--", "/docker-entrypoint.sh"]
