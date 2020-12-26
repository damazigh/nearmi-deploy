#!/bin/bash
#####=============================================#####
#####=  This file includes utils function script =#####
#####============================================="####
# author: a.djebarri
# logging function
function log() {
  LEVEL=$1
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
  > ${LOG_FILE}
  msg="[${LEVEL}][`date`] - ${CONTENT}"
  echo ${msg}
  echo ${msg} >> ${LOG_FILE}
}
# replace given key in file with a value
# $1 = key, $2 = template file, $3 = new value
# key and value should not contains "/" character
function replace() {
  key=$1
  template=$2
  newval=$3
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
	sed -i "s/${key}/${newval}/g" ${template}
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
	read -p "${q}" yn
	  case $yn in
		[Yy]* ) echo 1; break;;
		[Nn]* ) echo 0;;
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