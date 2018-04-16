#!/usr/bin/env bash
set -e

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
  if [ ! -f /.secret/munge.key ]; then
    while read i; do
      if [ "$i" = munge.key ]; then
        break;
      fi;
    done < <(inotifywait -e create,open --format '%f' --quiet /.secret --monitor)
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

### NO LONGER USED ###
# setup worker ssh to be passwordless
_ssh_copy_worker() {
  if [ ! -f /.secret/worker-secret.tar.gz ]; then
    while read i; do
      if [ "$i" = worker-secret.tar.gz ]; then
        break;
      fi;
    done < <(inotifywait -e create,open --format '%f' --quiet /.secret --monitor)
  fi
  cp /.secret/worker-secret.tar.gz /home/worker
  chown worker: /home/worker/worker-secret.tar.gz
  sudo -u worker /bin/bash -c 'cd ~/; tar -xzvf worker-secret.tar.gz'
}

# wait for worker user in shared /home volume
_wait_for_worker() {
  if [ ! -f /home/worker/.ssh/id_rsa.pub ]; then
    while read i; do
      if [ "$i" = id_rsa.pub ]; then
        break;
      fi;
    done < <(inotifywait -e create,open --format '%f' --quiet /home/worker/.ssh --monitor)
  fi
}

# run slurmd
_slurmd() {
  if [ ! -f /.secret/slurm.conf ]; then
    while read i; do
      if [ "$i" = slurm.conf ]; then
        break;
      fi;
    done < <(inotifywait -e create,open --format '%f' --quiet /.secret --monitor)
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
# _ssh_copy_worker
_wait_for_worker
_slurmd

tail -f /dev/null
