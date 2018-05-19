#!/usr/bin/env bash
set -e

_init_fstab() {
  if [[ ! -f /etc/fstab ]]; then
    cat > /etc/fstab << EOF
### <server>:</remote/export> </local/directory> <nfs-type> <options> 0 0
EOF
  fi
}

_export_nfs_mounts() {
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

_start_nfs_services() {
  rpcbind
  rpc.nfsd
  sleep 2
  echo "connecting to ${NFS_SERVER}"
  until [ $(ping ${NFS_SERVER} -c 3 2>&1 >/dev/null)$? ]; do
    echo -n "."
    sleep 2
  done
}

# start sshd server
_sshd_host() {
  if [ ! -d /var/run/sshd ]; then
    mkdir /var/run/sshd
    ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -N ''
  fi
  /usr/sbin/sshd
}

# start munge using existing key
_munge_start_using_key() {
  echo -n "cheking for munge.key"
  while [ ! -f /.secret/munge.key ]; do
    echo -n "."
    sleep 1
  done
  echo ""
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

# run slurmd
_slurmd() {
  if [ ! -f /.secret/slurm.conf ]; then
    echo -n "cheking for slurm.conf"
    while [ ! -f /.secret/slurm.conf ]; do
      echo -n "."
      sleep 1
    done
    echo ""
  fi
  mkdir -p /var/spool/slurm/d
  chown slurm: /var/spool/slurm/d
  cp /.secret/slurm.conf /etc/slurm/slurm.conf
  touch /var/log/slurmd.log
  chown slurm: /var/log/slurmd.log
  /usr/sbin/slurmd
}

### main ###
_start_nfs_services
_init_fstab
_export_nfs_mounts
mount -a

rpcinfo -p $NFS_SERVER
showmount -e $NFS_SERVER

_sshd_host
_munge_start_using_key
_wait_for_worker
_slurmd

tail -f /dev/null
