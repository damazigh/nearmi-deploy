#####=============================================#####
#####====== Script that kubernetes features  =====#####
#####=============================================#####
# author : a.djebarri
. ./utils.sh

function prepare_env() {
  if [ -z $1 ];
  then
    log "error" "hostname cannot be empty"
    exit -1
  fi
  log "info" "preparing k8s env..."
  swapoff -a;
  # enable bridge netfilter
  modprobe br_netfilter;
  echo 'net.bridge.bridge-nf-call-iptables = 1' > /etc/sysctl.d/20-bridge-nf.conf;
  sysctl --system;
  hostnamectl set-hostname $1
  log "info" "preparation complete"
}

function install_tools() {
  apt install -y \
  apt-transport-https \
  ca-certificates \
  curl \
  gnupg2 \
  dnsutils
}

function install_k8s() {
  curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -;
  echo 'deb https://apt.kubernetes.io/ kubernetes-xenial main' > /etc/apt/sources.list.d/kubernetes.list;
  apt update;
  apt install -y kubelet="${K8S_VERSION}" kubeadm="${K8S_VERSION}"
  if [ $1 = "master" ];
  then
    apt install -y kubectl="${K8S_VERSION}"
  fi
}


function init_master_node() {
  opts=""
  if [ ${K8S_CLUSTER_TYPE} -eq "dev" ];
  then
    log "info" "dev cluster ignoring cpu preflight check"
    set opts "--ignore-preflight-errors=NumCPU"
  fi
  if id "${K8S_MASTER_USER}" &>/dev/null; then
    log "info" "user exists (assuming group : ${K8S_MASTER_GROUP} exists too)"
  else
    log "info" "user doesn't exist creating user ${K8S_MASTER_USER} and group ${K8S_MASTER_GROUP}"
    useradd -m "${K8S_MASTER_USER}" -s /bin/bash;
    usermod -aG "sudo" "${K8S_MASTER_GROUP}";
    log "info" "user created, please set user : ${K8S_MASTER_USER} password"
    passwd ${K8S_MASTER_USER}
  fi
  log "info"  "Please, log to ${K8S_MASTER_USER} and executes the command below:"
  log "info" "sudo  kubeadm init --pod-network-cidr=${K8S_POD_NETWORK_CIDR} ${opts}"
}

function setup_k8s() {
  type=$1
  hostname=$2
  prepare_env ${hostname}
  install_tools
  install_k8s ${type}
  if [ ${type} = "master" ];
  then
    log "info" "node is designed as master node, init..."
    init_master_node
  fi
}