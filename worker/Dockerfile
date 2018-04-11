FROM mjstealey/slurm.base:17.11.5
MAINTAINER Michael J. Stealey <stealey@renci.org>

COPY docker-entrypoint.sh /docker-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/tini", "--", "/docker-entrypoint.sh"]
