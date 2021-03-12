#!/bin/bash
#####=============================================#####
#####=  Script that sets apache as reverse proxy =#####
#####=============================================#####
# author : a.djebarri

# function that install httpd if not found in default installation folder
function install_apache2() {
  install_pckg ${APACHE_PKG_NAME}
}

# function that install a mod if not present
# $1 = module to install, $2 = file that indicate if module is already present
function install_mod() {
    link_file=$1
  mod=$2
  if [ ! -L "${link_file}" ];
  then
    log "info" "mod_${mod} not found, trying to enable it"
	  a2enmod "${mod}"
	  log "success" "mod_${mod} enabled with success"
	  export SSL_CONFIG_REQUIRED="1"
  else
    log "warn" "mod_${mod} already enabled"
  fi
}


# disable default available vhosts
function dis_default_apache_conf() {
  if [ -f "${APACHE_AV_SITE_DIR}/default-ssl.conf" ];
  then
    log "info" "mod ssl was enabled and requires configuration, trying to configure it"
    a2dissite "000-default.conf"
    mkdir "${APACHE_AV_SITE_DIR}/_backup"
    mv "${APACHE_AV_SITE_DIR}/default-ssl.conf" "${APACHE_AV_SITE_DIR}/_backup"
    mv "${APACHE_AV_SITE_DIR}/000-default.conf" "${APACHE_AV_SITE_DIR}/_backup"
    log "success" "moved default conf to ${APACHE_AV_SITE_DIR}/_backup"
  else 
    log 'warn' 'default apache conf not found (already moved)'
  fi
}

function handle_selfSigned_certs() {
  log "info" "generating self signed certificate and key"
  if [ ! -d "/etc/ssl/private" ];
  then
    mkdir "/etc/ssl/private"
  fi
  if [ -f "./rootCA.crt" ];
  then
    log 'warn' "a root certificate was found at $(pwd)/rootCa.crt"
    keyFileAvailable=$(ask_yn 'Have you the associated keyfile of root CA ?')
    if [ "${keyFileAvailable}" -eq 1 ];
    then
      // TODO handle copy past certificate
    else
      generate_rootCA
      generate_certificate "${APACHE_RV_HOST}" "/etc/ssl/certs/apache.crt" "/etc/ssl/private/apache.key"
    fi
  else
    generate_rootCA
    generate_certificate "${APACHE_RV_HOST}" "/etc/ssl/certs/apache.crt" "/etc/ssl/private/apache.key"
  fi
}

function handle_existing_cert() {
  log "action" "copy paste your certificate to /etc/ssl/certs/apache.crt"
  log "action" "copy paste you key file to /etc/ssl/private/apache.key"
  complete=$(ask_yn "enter 'Y' when you did these operations")
  if [ [ ! -f /etc/ssl/certs/apache.crt ] -o [ ! -f /etc/ssl/private/apache.key ] ];
  then
    log "error" "one of required file not found"
    exit -1
  else
    log "info" "ssl configuration file found !"
  fi
}

function handle_dhParam() {
  if [ ! -f "/etc/ssl/certs/dhparam.pem" ]
  then
    openssl dhparam -out /etc/ssl/certs/dhparam.pem 4096
    check_file_exists '/etc/ssl/certs/dhparam.pem'
    log 'success' 'dhparam generated in /etc/ssl/certs/dhparam.pem'
  fi
}

# function to configure ssl 
# it generates a self signed certificate if user doesn't provide a signed certificate and it's relevant key
function configure_ssl() {
  if [ ${SSL_CONFIG_REQUIRED} -eq "1" ];
  then
    dis_default_apache_conf
    handle_dhParam
    # copy conf 
    mv ./conf/ssl-params.conf "${APACHE_AV_CONF_DIR}"
    a2enconf ssl-params
    log "success" "${APACHE_AV_CONF_DIR}/ssl-params.conf enabled"
    mv ./conf/ssl.conf "${APACHE_AV_SITE_DIR}"
    a2ensite ssl

    response=`ask_yn "Do you have a signed certificate ? yn"`
	  if [ "${response}" -eq 1 ];
	  then
      handle_existing_cert
	  else
      # generate self signed certs
      handle_selfSigned_certs 
	  fi
  else
    log "success" "ssl configuration should be already avaiable"
  fi
}

function configure_vhost() {
  if [ ${SSL_CONFIG_REQUIRED} -eq "1" ];
  then
    touch "${APACHE_AV_SITE_DIR}/nearmi.conf"
    cat ./template/cluster-vhost.template > "${APACHE_AV_SITE_DIR}/nearmi.conf"
    replace "#PORT#" "${APACHE_AV_SITE_DIR}/nearmi.conf" 443
    replace "#HOST#" "${APACHE_AV_SITE_DIR}/nearmi.conf" "${APACHE_RV_HOST}"
    replace "#NGINX_HOST#" "${APACHE_AV_SITE_DIR}/nearmi.conf" "${INGRESS_RV_HOST}"
    replace "#CLUSTER_CERT#" "${APACHE_AV_SITE_DIR}/nearmi.conf" "/etc/ssl/certs/apache.crt" '|'
    replace "#CLUSTER_KEY#" "${APACHE_AV_SITE_DIR}/nearmi.conf" "/etc/ssl/private/apache.key" '|'
    a2ensite nearmi
  else
    log "warn" "ssl vhost should be already configured"
  fi
  unset SSL_CONFIG_REQUIRED
}
## MAIN function that should be called in setup script ##
function setup_apache() {
  . ./utils.sh
  . ./ssl-utils.sh
  . ./config
  install_apache2
  install_mod "${APACHE_SSL_CONF_FILE}" "ssl" 
  install_mod "${APACHE_HEADER_LOAD_FILE}" "headers"
  install_mod "${APACHE_PROXY_LOAD_FILE}" "proxy"
  install_mod "${APACHE_PROXY_HTTP_LOAD_FILE}" "proxy_http"
  configure_ssl
  configure_vhost
}
