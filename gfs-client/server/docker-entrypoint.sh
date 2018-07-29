#!/usr/bin/env bash
set -e

_gluster_peer_status() {
  IFS=' ' read -r -a GFS_SERVERS_ARRAY <<< "$GFS_SERVERS"
  local server_count=$(wc -w <<< "$GFS_SERVERS")
  if $IS_PRIMARY; then
    for server in "${GFS_SERVERS_ARRAY[@]}"; do
      until ping -c1 $server &>/dev/null; do :; done
      if [[ "$(cat /etc/hosts | grep $(hostname))" = *"${server}"* ]]; then
        echo '### Do not peer self ###'
      else
        echo '### Add peer probe for '$server' ###'
        gluster peer probe $server
      fi
    done
  else
    echo '### Not primary node, sleep '$((2 * $server_count))'s ###'
    sleep $((2 * $server_count))s
  fi
  gluster peer status
}

_create_gluster_dirs() {
  IFS=' ' read -r -a GFS_SERVER_DIRS_ARRAY <<< "$GFS_SERVER_DIRS"
  for server_dir in "${GFS_SERVER_DIRS_ARRAY[@]}"; do
    if [[ ! -d ${server_dir} ]]; then
      mkdir -p $server_dir
    fi
  done
}

_gluster_volume_create() {
  IFS=' ' read -r -a GFS_SERVERS_ARRAY <<< "$GFS_SERVERS"
  IFS=':' read -r -a GFS_SERVER_DIRS_ARRAY <<< "$GFS_SERVER_DIRS"
  local replica_count=$(wc -w <<< "$GFS_SERVERS")
  if $IS_PRIMARY; then
    for server_dir in "${GFS_SERVER_DIRS_ARRAY[@]}"; do
      gluster_cmd='gluster volume create '$(basename ${server_dir})' replica '${replica_count}
      for server in "${GFS_SERVERS_ARRAY[@]}"; do
        gluster_cmd=$gluster_cmd' '$server':'$server_dir
      done
      gluster_cmd=$gluster_cmd' force'
      $gluster_cmd
      gluster volume start $(basename ${server_dir})
    done
  else
    echo '### Not primary node, sleep '$((2 * replica_count))'s ###'
    sleep $((2 * replica_count))s
  fi
  gluster volume info
}

### main ###
/usr/sbin/glusterd
_gluster_peer_status
_create_gluster_dirs
_gluster_volume_create

# keep fg process running forever
tail -f /dev/null

exit 0;
