#!/bin/bash
set -e

_start_nfs() {
  exportfs -a
  rpcbind
  rpc.statd
  rpc.nfsd
  rpc.mountd
}

_nfs_server_mounts() {
  IFS=':' read -r -a MNT_SERVER_ARRAY <<< "$NFS_SERVER_DIRS"
  for server_mnt in "${MNT_SERVER_ARRAY[@]}"; do
    if [[ ! -d $server_mnt ]]; then
        mkdir -p $server_mnt
    fi
    chmod -R 777 $server_mnt
    cat >> /etc/exports <<EOF
${server_mnt} *(rw,sync,no_subtree_check,no_root_squash,fsid=$(( ( RANDOM % 100 )  + 200 )))
EOF
  done
  cat /etc/exports
}

_sysconfig_nfs() {
  cat > /etc/sysconfig/nfs <<EOF
#
#
# To set lockd kernel module parameters please see
#  /etc/modprobe.d/lockd.conf
#

# Optional arguments passed to rpc.nfsd. See rpc.nfsd(8)
RPCNFSDARGS=""
# Number of nfs server processes to be started.
# The default is 8.
RPCNFSDCOUNT=${RPCNFSDCOUNT}
#
# Set V4 grace period in seconds
#NFSD_V4_GRACE=90
#
# Set V4 lease period in seconds
#NFSD_V4_LEASE=90
#
# Optional arguments passed to rpc.mountd. See rpc.mountd(8)
RPCMOUNTDOPTS=""
# Port rpc.mountd should listen on.
#MOUNTD_PORT=892
#
# Optional arguments passed to rpc.statd. See rpc.statd(8)
STATDARG=""
# Port rpc.statd should listen on.
#STATD_PORT=662
# Outgoing port statd should used. The default is port
# is random
#STATD_OUTGOING_PORT=2020
# Specify callout program
#STATD_HA_CALLOUT="/usr/local/bin/foo"
#
#
# Optional arguments passed to sm-notify. See sm-notify(8)
SMNOTIFYARGS=""
#
# Optional arguments passed to rpc.idmapd. See rpc.idmapd(8)
RPCIDMAPDARGS=""
#
# Optional arguments passed to rpc.gssd. See rpc.gssd(8)
# Note: The rpc-gssd service will not start unless the
#       file /etc/krb5.keytab exists. If an alternate
#       keytab is needed, that separate keytab file
#       location may be defined in the rpc-gssd.service's
#       systemd unit file under the ConditionPathExists
#       parameter
RPCGSSDARGS=""
#
# Enable usage of gssproxy. See gssproxy-mech(8).
GSS_USE_PROXY="yes"
#
# Optional arguments passed to blkmapd. See blkmapd(8)
BLKMAPDARGS=""
EOF
}

### main ###
_sysconfig_nfs
_nfs_server_mounts
_start_nfs

rpcinfo -p
showmount -e

tail -f /dev/null
