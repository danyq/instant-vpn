#!/bin/bash
#
# Installs and configures OpenVPN on an Ubuntu server,
# generates keys for the client and copies them
# to the current directory on the local machine.
#
# This should only be run on a brand new server with
# nothing else configured. Tested on Ubuntu 14.04 LTS.
#
# For an Ubuntu client:
# apt-get install network-manager-openvpn-gnome
# and be sure to select "Use LZO data compression"
# under advanced settings when configuring the VPN.

set -o errexit

if (($# != 1)); then
  echo "usage: `basename $0` <server>"
  exit 1
fi

ssh root@$1 "
set -o errexit
L='#######################################'

echo \$L 'installing software'
apt-get -y install openvpn easy-rsa

echo \$L 'generating server keys'
mkdir /etc/openvpn/easy-rsa
cp -r /usr/share/easy-rsa/* /etc/openvpn/easy-rsa/
cd /etc/openvpn/easy-rsa
source vars
./clean-all
./build-ca --batch
./build-key-server --batch server
./build-dh
cd keys
cp server.crt server.key ca.crt dh2048.pem /etc/openvpn/

echo \$L 'generating client keys'
cd /etc/openvpn/easy-rsa
source vars
./build-key --batch client

echo \$L 'configuring server'
cp /usr/share/doc/openvpn/examples/sample-config-files/server.conf.gz /etc/openvpn/
gzip -d /etc/openvpn/server.conf.gz
sed -iE 's/dh1024/dh2048/' /etc/openvpn/server.conf
echo 'push \"redirect-gateway def1 bypass-dhcp\"' >> /etc/openvpn/server.conf
echo 'push \"dhcp-option DNS 8.8.8.8\"' >> /etc/openvpn/server.conf

echo \$L 'configuring network'
sysctl -w net.ipv4.ip_forward=1
echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
sed -i '\$ d' /etc/rc.local
echo -e 'iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE\nexit 0' >> /etc/rc.local

echo \$L 'starting server'
service openvpn start
"

echo 'copying keys to current directory'
scp root@$1:'/etc/openvpn/easy-rsa/keys/{ca.crt,client.crt,client.key}' .

echo 'done!'
