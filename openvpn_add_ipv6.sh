#!/bin/bash
#
# Attempts to add IPv6 routing to an OpenVPN configuration.
# The server must already be configured with IPv6 support.
# Only to be run after setup_openvpn.sh.
#
# For an Ubuntu client, you may need to disable dnsmasq
# by removing or commenting out "dns=dnsmasq" in:
# /etc/NetworkManager/NetworkManager.conf
# possibly due to this bug:
# https://bugs.launchpad.net/ubuntu/+source/openvpn/+bug/1211110

set -o errexit

if (($# != 1)); then
  echo "usage: `basename $0` <server>"
  exit 1
fi

ssh root@$1 "
set -o errexit
L='#######################################'

echo \$L 'configuring server'
echo 'push \"redirect-gateway-ipv6 def1\"' >> /etc/openvpn/server.conf
echo 'tun-ipv6' >> /etc/openvpn/server.conf
echo 'server-ipv6 2001:db8:0:123::/64' >> /etc/openvpn/server.conf
echo 'push \"route-ipv6 2000::/3\"' >> /etc/openvpn/server.conf

echo \$L 'configuring network'
echo 'net.ipv6.conf.all.forwarding=1' >> /etc/sysctl.conf
echo 'net.ipv6.conf.all.accept_redirects=0' >> /etc/sysctl.conf
sysctl -p

sed -i '/^exit 0\$/ d' /etc/rc.local
echo 'ip6tables -t nat -A POSTROUTING -o eth0 -j MASQUERADE' >> /etc/rc.local
echo 'exit 0' >> /etc/rc.local
/etc/rc.local

echo \$L 'restarting server'
service openvpn restart
"

echo 'done!'
