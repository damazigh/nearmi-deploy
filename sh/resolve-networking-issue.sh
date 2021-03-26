#!/bin/bash
####======================================================####
####Scripts that allows handling env configuration========####
####======================================================####

. utils.sh
. config

log 'info' 'These script will tries to fix kubernetes networks issues'
log 'action' 'script will do these following actions:'
log 'action' 'reset the cluster with kubeadm reset'
log 'action' 'reset all iptables rules for both nf_tables x-tables'
log 'action' 'set up to ACCEPT the default policy for forwarding'
log 'warn' 'We hope you know what you are doing !' 

response=$(ask_yn 'Would you like to pursue the operation ?')
if [ ! "${response}" -eq 1 ]
then
  log 'warn' 'operation aborted'
  exit 0
fi

usr=$(whoami)
if [ ! "${usr}" = 'root' ]
then
  log 'error' "this script requires root acces - actual user: ${usr}"
  exit -1
fi
master=$(ask_yn "are you executing this script on master node ?")

kubeadm reset
if [ "${master}" -eq 1 ]
then
  rm -Rf /home/k8s/.kube
fi
rm -Rf /etc/kubernetes
rm -Rf /etc/cni/net.d/*
log 'success' 'cluster reset'

iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT
iptables -t nat -F
iptables -t mangle -F
iptables -F
iptables -X

ip6tables -P INPUT ACCEPT
ip6tables -P FORWARD ACCEPT
ip6tables -P OUTPUT ACCEPT
ip6tables -t nat -F
ip6tables -t mangle -F
ip6tables -F
ip6tables -X
log 'success' 'nf_tables rest with success'

iptables-legacy -P INPUT ACCEPT
iptables-legacy -P FORWARD ACCEPT
iptables-legacy -P OUTPUT ACCEPT
iptables-legacy -t nat -F
iptables-legacy -t mangle -F
iptables-legacy -F
iptables-legacy -X

ip6tables-legacy -P INPUT ACCEPT
ip6tables-legacy -P FORWARD ACCEPT
ip6tables-legacy -P OUTPUT ACCEPT
ip6tables-legacy -t nat -F
ip6tables-legacy -t mangle -F
ip6tables-legacy -F
ip6tables-legacy -X
log 'success' 'iptables-legacy reset with success'

iptables --policy FORWARD ACCEPT
log 'success' 'iptables forward policy set to ACCEPT'
log 'action' 'use kubeadm init or kubeadm join (depdends on node role)'