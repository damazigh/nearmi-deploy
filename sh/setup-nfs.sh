
#!/bin/bash
#####=============================================#####
#####====== Script that mount nfs srv/client =====#####
#####=============================================#####
# author : a.djebarri
install_srv_nfs() {
    log "info" "install nfs-kernel-server"
    install_pckg "nfs-kernel-server"
    
    dirs=($(echo $NFS_SHARED_DIRS | tr "," "\n"))
    log 'info' "${#dirs[@]} directories to process"
    for dir in "${dirs[@]}"
    do
    :
      if [ ! -d "${dir}" ];
      then
        log "info" "creating nfs shared directory (${dir})"
        mkdir "${dir}"
        chmod 777 "${dir}"
      fi
      ips=($(echo $NFS_AUTHORIZED_IPS | tr "," "\n"))
      nfs_cmd="${dir}"
      for ip in "${ips[@]}"
      do
      : 
        nfs_cmd="${nfs_cmd} ${ip}(rw,sync,no_subtree_check,no_root_squash)"
      done
      echo "${nfs_cmd}" >> /etc/exports

    done
    service nfs-kernel-server restart
    service nfs-kernel-server status
    log "success" "nfs dir : ${NFS_SHARED_DIRS} exposed with success to configured servers"
}

function mount_nfs() {
  if [ ! -d ${NFS_MOUNTED_DIR} ];
  then
    log "info" "creating to be mounted dir ${NFS_MOUNTED_DIR}"
    mkdir "${NFS_MOUNTED_DIR}"
    log "success" "dir created with success"
  fi
  mount  ${NFS_EXPOSING_NODE}:${NFS_SHARED_DIR} "${NFS_MOUNTED_DIR}"
}

function setup_nfs() {
  . utils.sh
  . ./config
  log "info" "installing nft common"
  install_pckg "nfs-common"
  type=$1
  if [ ${type} = "master" ];
  then
    install_srv_nfs
  elif [ ${type} = "worker" ];
  then
    log "warn" "This is for tests purpose only !!"
    res=`ask_yn "this will mount the volume at your mount directory, are you sure you want continue ? y/n"`
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