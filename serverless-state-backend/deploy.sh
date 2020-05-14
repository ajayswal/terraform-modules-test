#!/bin/bash
# load configuration variables
PACKAGE_NAME=terraform
source local.env

function usage() {
  echo "Usage: $0 [--install,--uninstall,--update,--installApi,--uninstallApi,--env]"
}

function install() {
  echo "Creating $PACKAGE_NAME package"
  bx fn package create $PACKAGE_NAME \
    -p services.storage.apiEndpoint "$STORAGE_API_ENDPOINT"\
    -p services.storage.instanceId "$STORAGE_RESOURCE_INSTANCE_ID"\
    -p versioning "$VERSIONING"

  echo "Creating actions"
  bx fn action create $PACKAGE_NAME/backend\
    backend.js \
    --web raw --annotation final true --kind nodejs:8
}

function uninstall() {
  echo "Removing actions..."
  bx fn action delete $PACKAGE_NAME/backend

  echo "Removing package..."
  bx fn package delete $PACKAGE_NAME

  echo "Done"
  bx fn list
}

function update() {
  echo "Updating actions..."
  bx fn action update $PACKAGE_NAME/backend    backend.js  --kind nodejs:8
}

function showenv() {
  echo "PACKAGE_NAME=$PACKAGE_NAME"
}

function installApi() {
  bx fn api create /terraform / GET    $PACKAGE_NAME/backend --response-type http
  bx fn api create /terraform / POST   $PACKAGE_NAME/backend --response-type http
  bx fn api create /terraform / PUT    $PACKAGE_NAME/backend --response-type http
  bx fn api create /terraform / DELETE $PACKAGE_NAME/backend --response-type http
}

function uninstallApi() {
  bx fn api delete /terraform
}

function recycle() {
  uninstallApi
  uninstall
  install
  installApi
}

case "$1" in
"--install" )
install
;;
"--uninstall" )
uninstall
;;
"--update" )
update
;;
"--env" )
showenv
;;
"--installApi" )
installApi
;;
"--uninstallApi" )
uninstallApi
;;
"--recycle" )
recycle
;;
"--createCOS" )
createCOS
;;
* )
usage
;;
esac
