#!/bin/bash
####======================================================####
####Scripts that allows handling env configuration========####
####======================================================####

### function that creates config
### check if file exits if not create it and add 'x' privilege on it
function create_config_if_needed() {
  cfg_file_path="../config";
  if [[ ! -f ${cfg_file_path} ]];
    then echo "file not found "$cfg_file_path" - creating it ...";
         touch ${cfg_file_path};
         ls 
         chmod +x ${cfg_file_path};
  fi
  echo "exporting config file "${cfg_file_path};
  export CONFIG_FILE=${cfg_file_path};
}
### append service configuration to global configuration
#$1 : configuration file to append
put_config() {
  svc_cfg_file=$1;
  echo "service file "${svc_cfg_file};
  echo "global config file" ${CONFIG_FILE};
  cat ${svc_cfg_file} >> ${CONFIG_FILE}
}
### function that handle copying service config to global config
### $1 : Service name
### $2 : configuration file to load
### $3 : service directory
function copy_config() {
  svc=$1;
  file=$2;
  
  cd $3; 
  if [[ -z ${svc} || -z ${file} ]];
    then echo 'ERR - both service and file are required';
    exit -1;
  elif [[ ! -f ${file} ]];
    then echo "file '"${file}"' doesn't exists";
    exit -1;
  else
    echo "create file if not exist...";
    create_config_if_needed;
    echo "append configuration";
    put_config ${file};
  fi
  # return to base folder
  cd -;
}