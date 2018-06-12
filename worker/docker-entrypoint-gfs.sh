#!/usr/bin/env bash
set -e

_gfs_init_fstab() {
  if [[ ! -f /etc/fstab ]]; then
    cat > /etc/fstab << EOF
### <server>:</remote/export> </local/directory> <glusterfs> defaults,_netdev 0 0
EOF
  fi
}

_gfs_export_mounts() {
  IFS=':' read -r -a MNT_SERVER_ARRAY <<< "$GFS_SERVER_DIRS"
  IFS=':' read -r -a MNT_CLIENT_ARRAY <<< "$GFS_CLIENT_DIRS"
  local gfs_server=$(echo $GFS_SERVERS | cut -d ' ' -f 1)
  for i in "${!MNT_CLIENT_ARRAY[@]}"; do
    if [[ ! -d ${MNT_CLIENT_ARRAY[$i]} ]]; then
      mkdir -p ${MNT_CLIENT_ARRAY[$i]}
    fi
    if grep -q ${MNT_CLIENT_ARRAY[$i]} /etc/fstab; then
      echo "### INFO: fstab entry for ${MNT_SERVER_ARRAY[$i]} already exists ###"
    else
      cat >> /etc/fstab <<EOF
${gfs_server}:/$(basename ${MNT_SERVER_ARRAY[$i]}) ${MNT_CLIENT_ARRAY[$i]} glusterfs defaults,_netdev,log-level=WARNING,log-file=/var/log/gluster.log 0 0
EOF
    fi
  done
  cat /etc/fstab
}

_gfs_mount_info() {
  IFS=':' read -r -a MNT_CLIENT_ARRAY <<< "$GFS_CLIENT_DIRS"
  for gfs_mount in "${MNT_CLIENT_ARRAY[@]}"; do
    echo '### Info for: '$gfs_mount' ###'
    mount | grep $gfs_mount
    df -h $gfs_mount
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
  sleep 1s
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
  sleep 1s
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
    sleep 1s
  fi
  mkdir -p /var/spool/slurm/d
  chown slurm: /var/spool/slurm/d
  cp /.secret/slurm.conf /etc/slurm/slurm.conf
  touch /var/log/slurmd.log
  chown slurm: /var/log/slurmd.log
  /usr/sbin/slurmd
#  /usr/sbin/slurmd -Dvvv ### enable for debugging (comment out call above)
}

_node_name_etc_hosts() {
#  local node_entry=$(cat /etc/hosts | grep $(hostname))
#  local new_node_entry=$node_entry' '${NODE_NAME}
  cp /etc/hosts /tmp/hosts
  sed -i "/$(cat /etc/hosts | grep $(hostname))/c\\$MY_HOST_ENTRY" /tmp/hosts
  source /.secret/controller_host_entry
  cat >> /tmp/hosts <<EOF
${CONTROLLER_HOST_ENTRY}
EOF
  cat /tmp/hosts > /etc/hosts
  echo "### cat /etc/hosts ###"
  cat /etc/hosts
}

### monitor /.secret/etc_hosts for new entries
_monitor_etc_hosts() {
  if ! grep -q ${MY_HOST_ENTRY} /.secret/etc_hosts; then
    cat >> /.secret/etc_hosts <<EOF
${MY_HOST_ENTRY}
EOF
  fi
  while read host_entry; do
    if ! grep -q ${host_entry} /etc/hosts; then
      cat >> /etc/hosts <<EOF
${host_entry}
EOF
    fi
  done < <(cat /.secret/etc_hosts)

  inotifywait -mr --timefmt '%d/%m/%y %H:%M' --format '%T %w %f' /.secret/etc_hosts | \
  while read date time dir file; do
    if ! grep -q ${MY_HOST_ENTRY} /.secret/etc_hosts; then
      cat >> /.secret/etc_hosts <<EOF
${MY_HOST_ENTRY}
EOF
    fi
    while read host_entry; do
      if ! grep -q ${host_entry} /etc/hosts; then
        cat >> /etc/hosts <<EOF
${host_entry}
EOF
      fi
    done < <(cat /.secret/etc_hosts)
  done
}

### main ###
gfs_server=$(echo $GFS_SERVERS | cut -d ' ' -f 1)
echo "connecting to ${gfs_server}"
until [ $(ping ${gfs_server} -c 3 2>&1 >/dev/null)$? ]; do
  echo -n "."
  sleep 1
done
echo ""
sleep 1s

_gfs_init_fstab
_gfs_export_mounts
mount -a
sleep 1s
_gfs_mount_info

echo "### waiting for controller_host_entry ###"
while [ ! -f /.secret/controller_host_entry ]; do
  echo -n "."
  sleep 1
done
echo ""
sleep 1s

export MY_HOST_ENTRY=$(cat /etc/hosts | grep $(hostname))' '${NODE_NAME}
_node_name_etc_hosts

_sshd_host
_munge_start_using_key
_wait_for_worker
_slurmd

_monitor_etc_hosts
tail -f /dev/null
