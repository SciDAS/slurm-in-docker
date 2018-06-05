#!/bin/bash
set -e

_init_fstab() {
  if [[ ! -f /etc/fstab ]]; then
    cat > /etc/fstab << EOF
### <server>:</remote/export> </local/directory> <glusterfs> defaults,_netdev 0 0
EOF
  fi
}

_export_gfs_mounts() {
  IFS=':' read -r -a MNT_SERVER_ARRAY <<< "$GFS_SERVER_DIRS"
  IFS=':' read -r -a MNT_CLIENT_ARRAY <<< "$GFS_CLIENT_DIRS"
  local gfs_server=$(echo $GFS_SERVERS | cut -d ' ' -f 1)
  for i in "${!MNT_CLIENT_ARRAY[@]}"; do
    if [[ ! -d ${MNT_CLIENT_ARRAY[$i]} ]]; then
      mkdir -p ${MNT_CLIENT_ARRAY[$i]}
    fi
    cat >> /etc/fstab <<EOF
${gfs_server}:$(basename ${MNT_SERVER_ARRAY[$i]}) ${MNT_CLIENT_ARRAY[$i]} glusterfs defaults,_netdev,log-level=WARNING,log-file=/var/log/gluster.log 0 0
EOF
  done
  cat /etc/fstab
}

_mount_info() {
  IFS=':' read -r -a MNT_CLIENT_ARRAY <<< "$GFS_CLIENT_DIRS"
  for gfs_mount in "${MNT_CLIENT_ARRAY[@]}"; do
    echo '### Info for: '$gfs_mount' ###'
    mount | grep $gfs_mount
    df -h $gfs_mount
  done
}

### main ###
gfs_server=$(echo $GFS_SERVERS | cut -d ' ' -f 1)
echo "connecting to ${gfs_server}"
until [ $(ping ${gfs_server} -c 3 2>&1 >/dev/null)$? ]; do
  echo -n "."
  sleep 1
done

_init_fstab
_export_gfs_mounts
sleep 5s
mount -a
sleep 1s
_mount_info

tail -f /dev/null

exit 0;
