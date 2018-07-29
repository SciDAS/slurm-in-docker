FROM krallin/centos-tini:7
MAINTAINER Michael J. Stealey <michael.j.stealey@gmail.com>

RUN yum -y install \
  glusterfs \
  glusterfs-fuse \
  attr

ENV GFS_SERVERS='server1' \
  GFS_SERVER_DIRS='/brick/share' \
  GFS_CLIENT_DIRS='/mnt/share'

COPY docker-entrypoint.sh /docker-entrypoint.sh

EXPOSE 24007 24008 49152-49199

ENTRYPOINT ["/usr/local/bin/tini", "--", "/docker-entrypoint.sh"]
