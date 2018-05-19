FROM krallin/centos-tini:7
MAINTAINER Michael J. Stealey <michael.j.stealey@gmail.com>

RUN rpmkeys --import file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7 && \
    yum -y --setopt=tsflags=nodocs install nfs-utils && \
    mkdir -p /nfs && \
    yum clean all

ENV RPCNFSDCOUNT=8 \
  NFS_SERVER_DIRS='/nfs/share'

COPY docker-entrypoint.sh /docker-entrypoint.sh

VOLUME ["/nfs"]
EXPOSE 111/udp 2049/tcp

ENTRYPOINT ["/usr/local/bin/tini", "--", "/docker-entrypoint.sh"]
