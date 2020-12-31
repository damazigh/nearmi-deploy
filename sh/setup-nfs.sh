#####=============================================#####
#####====== Script that mount nfs srv/client =====#####
#####=============================================#####
# author : a.djebarri
. utils.sh
install_srv_nfs() {
    log "info" "install nfs-kernel-server"
    apt install -y nfs-kernel-server
    if [ ! -d "${NFS_SHARED_DIR}" ];
    then
      log "info" "creating nfs shared directory (${NFS_SHARED_DIR})"
      mkdir "${NFS_SHARED_DIR}"
      chmod 777 "${NFS_SHARED_DIR}"
    fi
    readarray -td, a <<<"${NFS_AUTHORIZED_IPS},"; declare -p a;
    nfs_cmd="${NFS_SHARED_DIR}"
    for i in "${ips[@]}"
    do
      : 
      nfs_cmd="${nfs_cmd} ${ips[i]}(rw,sync,no_subtree_check,no_root_squash)"
    done
    service nfs-kernel-server restart
    log "info" "nfs dir : ${NFS_SHARED_DIR} exposed with success to configured servers"
}

function mount_nfs() {
  if [ ! -d ${NFS_MOUNTED_DIR} ];
  then
    log "info" "creating to be mounted dir ${NFS_MOUNTED_DIR}"
    mkdir "${NFS_MOUNTED_DIR}"
    log "info" "dir created with success"
  fi
  mount  ${NFS_EXPOSING_NODE}:${NFS_SHARED_DIR} "${NFS_MOUNTED_DIR}"
}

function setup_nfs() {
    log "info" "installing nft common"
    apt install -y nfs-common
    type=$1
    if [ ${type} = "master" ];
    then
      install_srv_nfs
    elif [ ${type} = "worker" ];
    then
      log "warn" "This is for tests purpose only !!"
      res=ask_yn "this will mount the volume at your mount directory, are you sure you want continue ? y/n"
      if [ ${res} -eq 1 ];
      then
        mount_nfs
      else
        log "info" "you awnsered no - nfs not mounted"
      fi
    else 
      log "error" "type must be 'master' or 'worker'"
      exit -1
    fi
}