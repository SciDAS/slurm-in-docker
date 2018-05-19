#!/usr/bin/env bash
set -e

SLURM_ACCT_DB_SQL=/slurm_acct_db.sql

_etc_fstab() {
  if [[ ! -f /etc/fstab ]]; then
    cat > /etc/fstab << EOF
### <server>:</remote/export> </local/directory> <nfs-type> <options> 0 0
EOF
  fi
  IFS=':' read -r -a MNT_SERVER_ARRAY <<< "$NFS_SERVER_DIRS"
  IFS=':' read -r -a MNT_CLIENT_ARRAY <<< "$NFS_CLIENT_DIRS"
  for i in "${!MNT_CLIENT_ARRAY[@]}"; do
    if [[ ! -d ${MNT_CLIENT_ARRAY[$i]} ]]; then
      mkdir -p ${MNT_CLIENT_ARRAY[$i]}
    fi
    cat >> /etc/fstab <<EOF
${NFS_SERVER}:${MNT_SERVER_ARRAY[$i]} ${MNT_CLIENT_ARRAY[$i]} nfs rw,hard,intr 0 0
EOF
  done
  cat /etc/fstab
}

_nfs_service() {
  rpcbind
  rpc.nfsd
  echo -n "NFS: connecting to ${NFS_SERVER}"
  until [ $(ping ${NFS_SERVER} -c 3 2>&1 >/dev/null)$? ]; do
    echo -n "."
    sleep 1
  done
  echo ""
  _etc_fstab
  mount -a
  rpcinfo -p $NFS_SERVER
  showmount -e $NFS_SERVER
}

# start sshd server
_sshd_host() {
  if [ ! -d /var/run/sshd ]; then
    mkdir /var/run/sshd
    ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -N ''
  fi
  /usr/sbin/sshd
}

# slurm database user settings
_slurm_acct_db() {
  echo "create database slurm_acct_db;" > $SLURM_ACCT_DB_SQL
  echo "create user '${STORAGE_USER}'@'${STORAGE_HOST}';" >> $SLURM_ACCT_DB_SQL
  echo "set password for '${STORAGE_USER}'@'${STORAGE_HOST}' = password('${STORAGE_PASS}');" >> $SLURM_ACCT_DB_SQL
  echo "grant usage on *.* to '${STORAGE_USER}'@'${STORAGE_HOST}';" >> $SLURM_ACCT_DB_SQL
  echo "grant all privileges on slurm_acct_db.* to '${STORAGE_USER}'@'${STORAGE_HOST}';" >> $SLURM_ACCT_DB_SQL
  echo "flush privileges;" >> $SLURM_ACCT_DB_SQL
}

# start database
_mariadb_start() {
  mysql_install_db
  chown -R mysql: /var/lib/mysql/ /var/log/mariadb/ /var/run/mariadb
  cd /var/lib/mysql
  mysqld_safe --user=mysql &
  cd /
  _slurm_acct_db
  sleep 5s
  mysql -uroot < $SLURM_ACCT_DB_SQL
}

# start munge using existing key
_munge_start_using_key() {
  if [ ! -f /.secret/munge.key ]; then
    echo -n "cheking for munge.key"
    while [ ! -f /.secret/munge.key ]; do
      echo -n "."
      sleep 1
    done
    echo ""
  fi
  cp /.secret/munge.key /etc/munge/munge.key
  chown -R munge: /etc/munge /var/lib/munge /var/log/munge /var/run/munge
  chmod 0700 /etc/munge
  chmod 0711 /var/lib/munge
  chmod 0700 /var/log/munge
  chmod 0755 /var/run/munge
  sudo -u munge /sbin/munged
  munge -n
  munge -n | unmunge
  remunge
}

# wait for worker user in shared /home volume
_wait_for_worker() {
  if [ ! -f /home/worker/.ssh/id_rsa.pub ]; then
    echo -n "cheking for id_rsa.pub"
    while [ ! -f /home/worker/.ssh/id_rsa.pub ]; do
      echo -n "."
      sleep 1
    done
    echo ""
  fi
}

# generate slurmdbd.conf
_generate_slurmdbd_conf() {
  cat > /etc/slurm/slurmdbd.conf <<EOF
#
# Example slurmdbd.conf file.
#
# See the slurmdbd.conf man page for more information.
#
# Archive info
#ArchiveJobs=yes
#ArchiveDir="/tmp"
#ArchiveSteps=yes
#ArchiveScript=
#JobPurge=12
#StepPurge=1
#
# Authentication info
AuthType=auth/munge
AuthInfo=/var/run/munge/munge.socket.2
#
# slurmDBD info
DbdAddr=$DBD_ADDR
DbdHost=$DBD_HOST
DbdPort=$DBD_PORT
SlurmUser=slurm
#MessageTimeout=300
DebugLevel=4
#DefaultQOS=normal,standby
LogFile=/var/log/slurm/slurmdbd.log
PidFile=/var/run/slurmdbd.pid
#PluginDir=/usr/lib/slurm
#PrivateData=accounts,users,usage,jobs
#TrackWCKey=yes
#
# Database info
StorageType=accounting_storage/mysql
StorageHost=$STORAGE_HOST
StoragePort=$STORAGE_PORT
StoragePass=$STORAGE_PASS
StorageUser=$STORAGE_USER
StorageLoc=slurm_acct_db
EOF
}

# run slurmdbd
_slurmdbd() {
  mkdir -p /var/spool/slurm/d \
    /var/log/slurm
  chown slurm: /var/spool/slurm/d \
    /var/log/slurm
  if [[ ! -f /home/config/slurmdbd.conf ]]; then
    echo "### generate slurmdbd.conf ###"
    _generate_slurmdbd_conf
  else
    echo "### use provided slurmdbd.conf ###"
    cp /home/config/slurmdbd.conf /etc/slurm/slurmdbd.conf
  fi
  /usr/sbin/slurmdbd
  cp /etc/slurm/slurmdbd.conf /.secret/slurmdbd.conf
}

### main ###
case $MOUNT_TYPE in
  local ) echo "### use LOCAL mounts ###"
    ;;
  nfs ) echo "### use NFS mounts ###"
    _nfs_service
    ;;
  glusterfs ) echo "### use GLUSTERFS mounts ###"
    ;;
  * ) echo "### use LOCAL mounts ###"
    ;;
esac

_sshd_host
_mariadb_start
_munge_start_using_key
_wait_for_worker
_slurmdbd

tail -f /dev/null
