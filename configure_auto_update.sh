#!/bin/bash
#
# Configures a fresh Ubuntu server for automatic updates
# with errors forwarded to a given email address.

set -o errexit

if (($# != 2)); then
  echo "usage: `basename $0` <server> <email_address>"
  exit 1
fi

SERVER=$1
EMAIL=$2

ssh root@$SERVER "
set -o errexit
L='#######################################'

echo \$L 'updating'
apt-get update
apt-get -y upgrade

echo \$L 'installing software'
debconf-set-selections <<< \"postfix postfix/mailname string $SERVER_NAME\"
debconf-set-selections <<< \"postfix postfix/main_mailer_type string 'Internet Site'\"
apt-get -y install postfix bsd-mailx unattended-upgrades update-notifier-common

echo \$L 'configuring auto updates'
echo 'APT::Periodic::Update-Package-Lists \"1\";
APT::Periodic::Unattended-Upgrade \"1\";' > /etc/apt/apt.conf.d/20auto-upgrades
echo 'Unattended-Upgrade::Mail \"root@localhost\";
Unattended-Upgrade::MailOnlyOnError \"true\";
Unattended-Upgrade::Remove-Unused-Dependencies \"true\";
Unattended-Upgrade::Automatic-Reboot \"true\";' >> /etc/apt/apt.conf.d/50unattended-upgrades
echo $EMAIL > ~/.forward
"

echo 'done!'
