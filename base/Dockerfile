FROM krallin/centos-tini:7
MAINTAINER Michael J. Stealey <stealey@renci.org>

ENV SLURM_VERSION=17.11.5 \
  MUNGE_UID=981 \
  SLURM_UID=982 \
  WORKER_UID=1000

RUN groupadd -g $MUNGE_UID munge \
  && useradd  -m -c "MUNGE Uid 'N' Gid Emporium" -d /var/lib/munge -u $MUNGE_UID -g munge  -s /sbin/nologin munge \
  && groupadd -g $SLURM_UID slurm \
  && useradd  -m -c "Slurm workload manager" -d /var/lib/slurm -u $SLURM_UID -g slurm  -s /bin/bash slurm \
  && groupadd -g $WORKER_UID worker \
  && useradd  -m -c "Workflow user" -d /home/worker -u $WORKER_UID -g worker  -s /bin/bash worker

RUN yum -y install \
  epel-release \
  && yum -y install \
  sudo \
  mariadb-server \
  mariadb-devel \
  munge \
  munge-libs \
  munge-devel \
  openssh-server \
  openssh-clients \
  inotify-tools

COPY rpms /packages
RUN yum -y localinstall \
  /packages/slurm-*.rpm

RUN rm -f /packages/slurm-*.rpm \
  && yum clean all \
  && rm -rf /var/cache/yum

VOLUME ["/.secret", "/storage", "/home"]

# 22:           SSH
# 3306:         MariaDB
# 6817:         Slurm Ctl D
# 6818:         Slurm D
# 6819:         Slurm DBD
# 60001-63000:  srun
EXPOSE 22 3306 6817 6818 6819 60001-63000
