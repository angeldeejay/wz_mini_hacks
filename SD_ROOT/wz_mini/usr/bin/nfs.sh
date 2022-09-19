#!/opt/wz_mini/bin/bash
set -e

. /opt/wz_mini/wz_mini.conf

NFS_MOUNT=/opt/wz_mini/log/nfs
if [[ -e $NFS_MOUNT.log || -L $NFS_MOUNT.log ]]; then
  i=0
  while [[ -e $NFS_MOUNT.log.$i || -L $NFS_MOUNT.log.$i ]]; do
    let i++
  done
  mv $NFS_MOUNT.log $NFS_MOUNT.log.$i
  NFS_MOUNT=$NFS_MOUNT
fi
touch -- "$NFS_MOUNT".log

function mount_nfs() {
  while "$ENABLE_NFSv4" == "true"; do
    until [ -d /media/mmc/record ]; do
      sleep 1
      echo "waiting for mmc to mount"
    done

    if [[ $(cat /proc/mounts | grep nfs | grep '/media/mmc/record' | wc -l) -eq 0 ]]; then
      mount -t nfs4 -o nolock,rw,noatime,nodiratime,retry=100,tcp 192.168.0.2:/Cameras/$CAMERA_HOST /media/mmc/record >$NFS_MOUNT.log 2>&1 &
      echo "mmc mounted"
    fi
    sleep 1
  done
}

function umount_nfs() {
  if [[ $(cat /proc/mounts | grep nfs | grep '/media/mmc/record' | wc -l) -gt 0 ]]; then
    umount -f /media/mmc/record >$NFS_MOUNT.log 2>&1 &
  fi
}

case "$1" in
start)
  mount_nfs
  ;;

stop)
  umount_nfs
  ;;
esac
