#!/bin/bash
####======================================================####
####Scripts that allows handling env configuration========####
####======================================================####

. utils.sh
. config


log 'info' 'This script will update the related kubernetes manifest.yml'
response=$(ask_yn 'Are you sure you want to pursue the operation ?')
if [ ${response} -eq 1 ]
then
  find /tmp/nearmi-deploy/manifest/ -name "*.yml" -exec sed -i -e "s/#MANIFEST_IP_MASTER#/${MANIFEST_IP_MASTER}/g" {} +
  find /tmp/nearmi-deploy/manifest/ -name "*.yml" -exec sed -i -e "s/#MANIFEST_REGISTRY#/${MANIFEST_REGISTRY}/g" {} +
  find /tmp/nearmi-deploy/manifest/ -name "*.yml" -exec sed -i -e "s/#MANIFEST_CLUSTER_HOST#/${MANIFEST_CLUSTER_HOST}/g" {} +
  echo 'Please enter your gitlab ci token'
  read token
  MANIFEST_GITLAB_REG_TOKEN=$(echo "${token}" | base64)
  find /tmp/nearmi-deploy/manifest/ -name "*.yml" -exec sed -i -e "s/#MANIFEST_GITLAB_REG_TOKEN#/${MANIFEST_GITLAB_REG_TOKEN}/g" {} +
  log 'success' 'manifests should be updated'
  log 'action' 'before executing the manifests, please check them if they seem ok'
else
  log 'warn' 'Operation aborted'
fi
