#!/bin/bash
#####=============================================#####
#####======   Script that commons features  ======#####
#####=============================================#####
# author : a.djebarri
function install_fail2ban() {
  if [ ! -d "${FAIL2BAN_DIR}" ];
    then
    log "info" "fail2ban not installed trying to install it"
    apt install -y fail2ban
    log "success" "fail2ban installed"
  else
    log "warn" "fail2ban already installed"
  fi
}

function configure_fail2ban() {
  if [ ! -f "${FAIL2BAN_CONF_FILE}" ];
    then
    log "info" "fail2ban not configured try to configure it"
    touch "${FAIL2BAN_CONF_FILE}"
    cat <<EOF >> "${FAIL2BAN_CONF_FILE}"
    [DEFAULT]
    # findtime: 1 day
    findtime = 86400
    # bantime: 1 year
    bantime = 31536000
    # Call iptables to ban IP address
    banaction = iptables-multiport
    # Enable sshd protection
    [sshd]
    enabled = true
EOF
    log "success" "fail2ban configured"
  else 
    log "warn" "fail2ban already configured"
  fi
}

function setup_commons() {
  . ./utils.sh
  . ./config
  # fail2ban
  install_fail2ban
  configure_fail2ban
  service fail2ban restart
}