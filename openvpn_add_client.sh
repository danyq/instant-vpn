#!/bin/bash
#
# Generates an additional set of OpenVPN client keys and
# copies them to the current directory.
# client_name is any unique name for the client.

set -o errexit

if (($# != 2)); then
  echo "usage: `basename $0` <server> <client_name>"
  exit 1
fi

SERVER=$1
CLIENT_NAME=$2

ssh root@$SERVER "
set -o errexit
echo 'adding client $CLIENT_NAME'
cd /etc/openvpn/easy-rsa
source vars
./build-key --batch $CLIENT_NAME
"

echo 'copying keys to current directory'
scp root@$SERVER:"/etc/openvpn/easy-rsa/keys/{ca.crt,$CLIENT_NAME.crt,$CLIENT_NAME.key}" .

echo 'done!'
