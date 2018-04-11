FROM mjstealey/slurm.base:17.11.5
MAINTAINER Michael J. Stealey <stealey@renci.org>

ENV USE_SLURMDBD=true \
  CLUSTER_NAME=snowflake \
  CONTROL_MACHINE=controller \
  SLURMCTLD_PORT=6817 \
  SLURMD_PORT=6818 \
  ACCOUNTING_STORAGE_HOST=database \
  ACCOUNTING_STORAGE_PORT=6819 \
  PARTITION_NAME=docker

COPY docker-entrypoint.sh /docker-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/tini", "--", "/docker-entrypoint.sh"]
