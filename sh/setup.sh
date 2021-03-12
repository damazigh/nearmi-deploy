#!/bin/bash
#####=============================================#####
#####========= Script that install a node ========#####
#####=============================================#####
# author : a.djebarri
source ./utils.sh
source ./setup-commons.sh
source ./setup-nfs.sh
source ./setup-k8s.sh
source ./setup-apache2.sh

type=$1
hostname=$2
if [ -z "${type}" ];
then
  log 'error' 'Missing parameter type node (accepted values : master | worker)'
  exit -1
fi

if [ "${type}" != "master" ] && [ "${type}" != "worker" ];
then
  log 'error' "Invalid value expected (master | worker) and got ${type}"
  exit -1
fi

if [ -z "${hostname}" ];
then
  log 'error' "hostame cannot be empty"
  exit -1
fi

# setup common utilities
log 'info' 'Installing commons utilities...'
setup_commons
log 'success' 'Common utilities installed'

# setup node type related
if [ "${type}" = 'master' ];
then
  log 'info' 'installing kubernetes on master node...'
  setup_k8s 'master' "${hostname}"
  log 'success' 'kubernetes installed'
  log 'info' 'installing nfs on master node'
  setup_nfs 'master'
  log 'success' 'nfs installed'
  log 'info' 'Installing apache 2...'
  setup_apache
  log 'success' 'apache 2 installed'
else
  log 'info' 'installing kubernetes on worker node...'
  setup_k8s 'worker' "${hostname}"
  log 'success' 'kubernetes installed'
  log 'info' 'installing nfs on master node'
  setup_nfs 'worker'
  log 'sucess' 'nfs installed'
fi