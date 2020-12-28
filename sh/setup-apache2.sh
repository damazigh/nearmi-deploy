#####=============================================#####
#####=  Script that sets apache as reverse proxy =#####
#####=============================================#####
# author : a.djebarri
# Load utils function
. ./utils.sh
# function that install httpd if not found in default installation folder
function install_apache2() {
  if [ ! -d "${APACHE_DIR}" ];
  then
    log "info" "apache 2 not installed - trying to install it"
    apt install -y ${APACHE_PKG_NAME}
	log "info" "apache 2 installed with success"
  else 
    log "info" "apache 2 already installed"
  fi
}

# function that install a mod if not present
# $1 = module to install, $2 = file that indicate if module is already present
function install_mod() {
  mod=$1
  link_file=$2
  if [ ! -L "${link_file}" ];
  then
    log "info" "mod_${mod} not found, trying to enable it"
	  a2enmod ${mod}
	  log "info" "mod_${mod} enabled with success"
	  export SSL_CONFIG_REQUIRED="1"
  else
    log "info" "mod_${mod} already enabled"
  fi
}

# function to configure ssl 
# it generates a self signed certificate if user doesn't provide a signed certificate and it's relevant key
function configure_ssl() {
  if [ ${SSL_CONFIG_REQUIRED} -eq "1" ];
  then
    # disable default available vhosts
    log "info" "mod ssl was enabled and requires configuration, trying to configure it"
	  a2dissite "000-default.conf"
    mkdir "${APACHE_AV_SITE_DIR}/_backup"
    mv "${APACHE_AV_SITE_DIR}/default-ssl.conf" "${APACHE_AV_SITE_DIR}/_backup"
    mv "${APACHE_AV_SITE_DIR}/000-default.conf" "${APACHE_AV_SITE_DIR}/_backup"
    log "info" "moved default conf to ${APACHE_AV_SITE_DIR}/_backup"
      # generate and copy ssl configuration
    log "info" "generating suitable DHParameters (this actions should takes few minutes)"
    #openssl dhparam -out /etc/ssl/certs/dhparam.pem 4096
    mv ./conf/ssl-params.conf "${APACHE_AV_CONF_DIR}"
    a2enconf ssl-params
    log "info" "${APACHE_AV_CONF_DIR}/ssl-params.conf enabled"
    mv ./conf/ssl.conf "${APACHE_AV_SITE_DIR}"
    a2ensite ssl
    response=`ask_yn "Do you have a signed certificate ? yn"`
	  if [ response -eq 1 ];
	  then
	    log "info" "copy paste your certificate to /etc/ssl/certs/apache.crt"
      log "info" "copy paste you key file to /etc/ssl/private/apache.key"
      complete=ask_yn "enter 'Y' when you did these operations"
      if [ [ ! -f /etc/ssl/certs/apache.crt ] -o [ ! -f /etc/ssl/private/apache.key ] ];
      then
        log "error" "one of required file not found"
        exit -1
	    else
	      log "info" "ssl configuration file found !"
	    fi
	  else
      log "info" "generating self signed certificate and key (operation may takes some time)"
      if [ ! -d "/etc/ssl/private" ];
      then
        mkdir "/etc/ssl/private"
      fi
	    openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/apache.key -out /etc/ssl/certs/apache.crt
	    log "info" "generated certificate at /etc/ssl/certs/apache.crt"
	    log "info" "generated private key at /etc/ssl/private/apache.key"
	  fi
  else
    log "info" "ssl configuration should be already avaiable"
  fi
}

function configure_vhost() {
  if [ ${SSL_CONFIG_REQUIRED} -eq "1" ];
  then
   touch "${APACHE_AV_SITE_DIR}/nearmi.conf"
   cat ./template/vhost.template > "${APACHE_AV_SITE_DIR}/nearmi.conf"
   replace "#PORT#" "${APACHE_AV_SITE_DIR}/nearmi.conf" 443
   replace "#HOST#" "${APACHE_AV_SITE_DIR}/nearmi.conf" "cluster.nearmi-dev"
   a2ensite nearmi
  else
    log "info" "ssl vhosh should be already configured"
  fi
  unset SSL_CONFIG_REQUIRED
}
## MAIN function that should be called in setup script ##
function setup_apache() {
  install_apache2
  install_mod "${APACHE_SSL_CONF_FILE}" "ssl" 
  install_mod "${APACHE_HEADER_LOAD_FILE}" "headers"
  install_mod "${APACHE_PROXY_LOAD_FILE}" "proxy"
  configure_ssl
  configure_vhost
}
