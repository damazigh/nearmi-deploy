#!/bin/bash
#####=============================================#####
#####=  This file includes utils function script =#####
#####============================================="####
# author: a.djebarri
# logging function
function log() {
  RED='\033[0;31m' # red
  NC='\033[0m' # No Color
  GREEN='\033[0;32m' # green
  YELLOW='\033[0;33m' # yellow
  CYAN='\033[0;36m' # cyan
  
  
  COLOR="${NC}"
  LEVEL=$1
  if [ "${LEVEL}" = 'error' ];
  then
    COLOR="${RED}"
  elif [ "${LEVEL}" = 'success' ];
  then
    COLOR="${GREEN}"
  elif [ "${LEVEL}" = 'warn' ];
  then
    COLOR="${YELLOW}"
  elif [ "${LEVEL}" = 'action' ];
  then
    COLOR="${CYAN}"
  fi

  shift
  CONTENT=$@
  if [ ! -f ${LOG_FILE} ] || [ -z ${LOG_FILE} ];
  then
    
	if [ ! -d "/var/log/nearmi" ];
	then
		  mkdir "/var/log/nearmi"
	fi
	now=`date +"%d_%m_%Y"`
	export LOG_FILE="/var/log/nearmi/install-"${now}".log"
	echo test ${LOG_FILE}
	touch ${LOG_FILE}
  fi
  if [ -z ${LEVEL} ];
  then
	LEVEL="info"
  fi
  msg="[${LEVEL}][`date`] - ${CONTENT}"
  echo -e "${COLOR}${msg}"
  echo -e "${COLOR}${msg}" >> ${LOG_FILE}
  echo -e "${NC}"
  
}
# replace given key in file with a value
# $1 = key, $2 = template file, $3 = new value
# key and value should not contains "/" character
function replace() {
  key=$1
  template=$2
  newval=$3
  sep='/'
  if [ ! -z $4 ];
  then
    sep=$4
  fi

  if [ -z ${key} ];
  then
	  log "warn" "cannot replace empty key"
  elif [ ! -f ${template} ];
  then
	  log "warn" "given file doesn't exist : ${template}"
  elif [ -z ${newval} ];
  then
	  log "warn" "cannot set empty value for key : ${key}"
  else
	  sed -i "s${sep}${key}${sep}${newval}${sep}g" ${template}
  fi
}

# function that ask user for yes/no statement
#$1= statement (question)
function ask_yn() {
  q=$1;
  if [ -z "${q}" ];
  then
	log "error" "cannot ask empty question to user"
	exit -1
  else
	while true; do
	read -p "${q} " yn
	  case $yn in
		[Yy]* ) echo 1; break;;
		[Nn]* ) echo 0;break;;
		* ) echo "Please answer yes or no.";;
	  esac
	done
  fi
}
#function that finds text at line number in file
function text_at() {
  txt=$1
  fil=$2
  t=`cat ${fil} | grep "${txt}" -n`
  res=`echo $t | head -n 1 | cut -d: -f1`
  reg='^[0-9]+$'
  if ! [[ ${res} =~ ${reg} ]];
  then
    log "error" "could not find anchor ${text} in file : ${fil}"
	exit -1
  fi
  echo "$((${res} + 1))"
}
#function that inserts text at a given position
#$1 = content to insert, $2 = position, $3 = file, $4 = separator (use to replace return char or backspace)
function insert_at() {
  txt=$1
  at=$2
  f=$3
  sep=$4
  if [ -z ${sep} ];
  then
    sep='|'
  fi
  if [ -z "${txt}" ];
  then
	log "error" "cannot insert empty text to file : ${f}"
	exit -1
  elif [ ! -f ${f} ];
  then
	log "error" "given file doesn't exists : ${f}"
	exit -1
  else
    salt=`echo ${txt} | tr '\n''\r' ${sep}`
	sed -e "${at}i${salt}" -i ${f}
	sed -i "s/${sep}/\n/g" ${f}
  fi
}
#function that install Calicoctl 
function install_calicoctl() {
 cd /usr/local/bin/
 curl -O -L  https://github.com/projectcalico/calicoctl/releases/download/v3.17.1/calicoctl /usr/local/bin/
 chmod +x calicoctl
}
#function that install network utils
function install_net_utils() {
 apt-get install tcpdump
 apt-get install telnet
}

function not_empty() {
  value=$1
  name=$2

  if [ -z "${name}" ];
  then
    log 'error' 'parameter name could not be empty'
    exit -1
  fi

  if [ -z "${value}" ]
  then
    log 'error' "Missing parameter : ${name}"
    exit -1
  fi
}

function verify_pckg_installed() {
  pckg=$1
  not_empty "${pckg}" 'package'
  status=$(cut -d ':' -f2 <<< $(dpkg -s "${pckg}" | sed -n 2p))
  if [ -z "${status}" ];
  then
    log 'error' "Pacakge : ${pckg} is not installed"
    exit -1
  else
    log 'success' "Package : ${pckg} is installed. Status: ${status}"
  fi
}

function install_pckg() {
  pckg=$1
  version=$2
  cmd="${pckg}"
  not_empty "${pckg}" 'package'

  if [ ! -z "${version}" ]
  then
    cmd="${cmd}=${version}"
  fi

  status=$(cut -d ':' -f2 <<< $(dpkg -s "${pckg}" | sed -n 2p))
  if [ -z "${status}" ];
  then
    apt install -y "${cmd}"
    verify_pckg_installed "${pckg}"
  else
    log 'warn' "Package : ${pckg} alredy installed"
  fi
}

function check_file_exists() {
  file=$1
  not_empty "${file}" 'file'

  if [ ! -f "${file}" ]
  then
    log 'error' "File: ${file} doesn't exist"
    exit -1
  fi
}

function add_action() {
  action=$1
  not_empty "${action}" "action"
  if [ ! -f "/tmp/actions" ];
  then
    touch /tmp/actions
  fi
  echo "${action}" >> /tmp/actions
}

function display_actions() {
  if [ -f "/tmp/action" ]
  then
    log 'warn' '/!\ HOLD ON /!\ To complete installation you should perform these actions mannualy'
    cat /tmp/actions
  fi
}