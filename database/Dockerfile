FROM scidas/slurm.base:17.11.5
MAINTAINER Michael J. Stealey <stealey@renci.org>

ENV DBD_ADDR=database \
  DBD_HOST=database \
  DBD_PORT=6819 \
  STORAGE_HOST=database.local.dev \
  STORAGE_PORT=3306 \
  STORAGE_PASS=password \
  STORAGE_USER=slurm \
  MOUNT_TYPE=local \
  NFS_SERVER=nfs-server \
  NFS_SERVER_DIRS=/nfs/secret:/nfs/home:/nfs/modules:/nfs/modulefiles \
  NFS_CLIENT_DIRS=/secret:/home:/opt/apps/Linux:/opt/apps/modulefiles/Linux

# clean up
RUN rm -f /packages/slurm-*.rpm /packages/openmpi-*.rpm \
  && yum clean all \
  && rm -rf /var/cache/yum

COPY docker-entrypoint.sh /docker-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/tini", "--", "/docker-entrypoint.sh"]
