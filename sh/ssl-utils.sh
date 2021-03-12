#!/bin/bash
#####=============================================#####
#####=== This file includes ssl utils function ===#####
#####============================================="####

#generate a root certifcate authority certificate
function generate_rootCA() {
  openssl genrsa -des3 -out /etc/ssl/private/rootCA.key 4096
  check_file_exists "/etc/ssl/private/rootCA.key"
  log 'success' 'root certificate key generated in /etc/ssl/private/rootCA.key'
  openssl req -x509 -new -nodes -key /etc/ssl/private/rootCA.key -sha256 -days 1024 -out /tmp/rootCA.crt
  check_file_exists "/tmp/rootCA.crt"
  mv /tmp/rootCA.crt /usr/local/share/ca-certificates/
  log 'success' 'authority certification generated in /usr/local/share/ca-certificates/'
  update-ca-certificates
}

# function that generate certificate
#$1=certificate signed for domain, $2 = destination file
function generate_certificate() {
  domain=$1
  crtDestFile=$2
  keyDestFile=$3

  not_empty "${domain}" 'domain'
  not_empty "${crtDestFile}" 'certificate destination file'
  not_empty "${keyDestFile}" 'key destination file'

  log 'info' 'generating key file'
  openssl genrsa -out "${keyDestFile}" 2048
  check_file_exists "${keyDestFile}"
  log 'success' "generated key file ${keyDestFile}"

  log 'info' 'generating the signing (csr)'
  openssl req -new -key "${keyDestFile}" -out /tmp/signing.csr
  check_file_exists '/tmp/signing.csr'
  log 'success' 'generated the signing in /tmp/signing.csr'

  log 'info' 'generating the certificate'
  check_file_exists '/etc/ssl/private/rootCA.key'
  check_file_exists '/usr/local/share/ca-certificates/rootCA.crt'

  openssl x509 -req -in "/tmp/signing.csr" -CA "/usr/local/share/ca-certificates/rootCA.crt" -CAkey "/etc/ssl/private/rootCA.key" -CAcreateserial -out "${crtDestFile}" -days 600 -sha256
  check_file_exists "${crtDestFile}"
  log 'success' "certificate generated in ${crtDestFile}"
  rm -f /tmp/signing.csr
}
