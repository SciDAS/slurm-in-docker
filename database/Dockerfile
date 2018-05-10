FROM scidas/slurm.base:17.11.5
MAINTAINER Michael J. Stealey <stealey@renci.org>

ENV DBD_ADDR=database \
  DBD_HOST=database \
  DBD_PORT=6819 \
  STORAGE_HOST=database.local.dev \
  STORAGE_PORT=3306 \
  STORAGE_PASS=password \
  STORAGE_USER=slurm

# clean up
RUN rm -f /packages/slurm-*.rpm /packages/openmpi-*.rpm \
  && yum clean all \
  && rm -rf /var/cache/yum

COPY docker-entrypoint.sh /docker-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/tini", "--", "/docker-entrypoint.sh"]
