#####=============================================#####
#####======   Script that sets master node  ======#####
#####============================================="####
# author : a.djebarri
# Load utils function
. ./utils.sh
# function that install httpd if not found in default installation folder
function install_apache2() {
  if [ ! -d "/etc/httpd" ];
  then
    log "warn" "apache 2 not installed - trying to install it"
    dnf install -y httpd
	log "info" "apache 2 installed with success"
  else 
    log "info" "apache 2 already installed"
  fi
}

# function that installs mod_ssl if not found default configuration file
function install_modssl() {
  if [ ! -f "/etc/httpd/conf.d/ssl.conf" ];
  then
    log "info" "mod ssl not found, trying to install it"
	dnf install -y mod_ssl
	log "info" "mod_ssl installed with success"
	export SSL_CONFIG_REQUIRED="1"
  else
    log "info" "mod_ssl already installed"
  fi
}

# function to configure ssl 
# it generates a self signed certificate if user doesn't provide a signed certificate and it's relevant key
function configure_ssl() {
  if [ ${SSL_CONFIG_REQUIRED} -eq "1" ];
  then
    log "info" "mod ssl was installed and requires configuration, trying to configure it"
	mkdir /etc/httpd/conf.d/_backup
	mv /etc/httpd/conf.d/ssl.conf /etc/httpd/conf.d/_backup/ssl.default.conf
	log "info" "moved default ssl conf to /etc/httpd/conf/httpd/conf.d/ssl.default.conf"
	log "info" "generating suitable DHParameters (this actions should takes few minutes)"
	openssl dhparam -out /etc/ssl/certs/dhparam.pem 4096
	mv ./conf/ssl-params.conf /etc/httpd/conf.d/
	mv ./conf/ssl.conf /etc/httpd/conf.d/
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
   position=`text_at "# virtual" "/etc/httpd/conf/httpd.conf"`
   text=`cat ./template/vhost.template`
   insert_at "${text}" ${position} "/etc/httpd/conf/httpd.conf"
   log "info" "vhost template configuration insered in file /etc/httpd/conf/httpd.conf at position ${position}"
   replace "#PORT#" "/etc/httpd/conf/httpd.conf" 443
   replace "#HOST#" "/etc/httpd/conf/httpd.conf" "cluster.nearmi-dev"
  else
    log "info" "ssl vhosh should be already configured"
  fi
  unset SSL_CONFIG_REQUIRED
}
## MAIN PROGRAM ##
# apache related configuration
install_apache2
install_modssl
configure_ssl
configure_vhost