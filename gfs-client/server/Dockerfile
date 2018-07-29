FROM krallin/centos-tini:7
MAINTAINER Michael J. Stealey <michael.j.stealey@gmail.com>

RUN yum -y install \
  centos-release-gluster \
  && yum -y install \
  glusterfs-server

ENV GFS_SERVERS='server' \
  IS_PRIMARY=true \
  GFS_SERVER_DIRS='/brick/share'

COPY docker-entrypoint.sh /docker-entrypoint.sh

VOLUME ["/brick"]
EXPOSE 2376/tcp 2377/tcp 7946/tcp 7946/udp 4789/udp

ENTRYPOINT ["/usr/local/bin/tini", "--", "/docker-entrypoint.sh"]
