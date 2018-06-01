#!/usr/bin/env bash
set -e

#get arguments
usage() {
  cat <<-EOF
  Usage: $0 -c <control_machine> -ah <accounting_storage_host> -cn <compute_nodes> 

  Initial setup of Slurm 

  Options:
      -c
      -ah
      -cn
      
EOF
  exit 1
}

while getopts c:ah:cn OPT;do
    case "${OPT}" in
        db) USE_SLURMBDB=${OPTARG};; 
	ah) ACCOUNTING_STORAGE_HOST=${OPTARG};; 
	cn) COMPUTE_NODES=${OPTARG};; 
    esac
done

#[ ! ${FLOCK_TO} -o ! ${SSH_KEY} -o ! ${IRODS_USER} -o ! ${IRODS_PW} ] && usage

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
_sshd_host
_munge_start_using_key
_wait_for_worker
_slurmd

tail -f /dev/null
