#!/bin/bash
#
# Installs and configures PPTP on an Ubuntu server.
#
# This should only be run on a brand new server with
# nothing else configured. Tested on Ubuntu 14.04 LTS.
#
# For the client:
# be sure to select "Use Point-to-Point encryption (MPPE)"
# under advanced settings when configuring the VPN.
#
# WARNING! PPTP is insecure, and this configuration
# does not route all traffic such as IPv6.

set -o errexit

if (($# != 3)); then
  echo "usage: `basename $0` <server> <pptp_user> <pptp_pass>"
  exit 1
fi

USERNAME=$2
PASSWORD=$3

ssh root@$1 "
set -o errexit
L='#######################################'

echo \$L 'installing software'
apt-get -y install pptpd

echo \$L 'configuring server'
echo 'localip 192.168.0.1' >> /etc/pptpd.conf
echo 'remoteip 192.168.0.234-238,192.168.0.245' >> /etc/pptpd.conf
echo 'ms-dns 8.8.8.8' >> /etc/ppp/pptpd-options
echo 'ms-dns 8.8.4.4' >> /etc/ppp/pptpd-options
echo \"$USERNAME pptpd $PASSWORD *\" >> /etc/ppp/chap-secrets

echo \$L 'configuring network'
sysctl -w net.ipv4.ip_forward=1
echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
sed -i '\$ d' /etc/rc.local
echo -e 'iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE\nexit 0' >> /etc/rc.local

echo \$L 'starting server'
service pptpd restart
"

echo 'done!'
