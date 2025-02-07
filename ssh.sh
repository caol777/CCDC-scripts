#!/bin/bash

# Check if the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Variables
SSH_CONFIG="/etc/ssh/sshd_config"
NEW_SSH_PORT=2222
ALLOWED_USERS="jeremy.rover maxwell.starling jack.harris emily.chen william.wilson melissa.chen john.taylor laura.harris alan.chen anna.wilson matthew.taylor"

# Backup the original SSH configuration file
cp $SSH_CONFIG ${SSH_CONFIG}.bak

# Disable root login
sed -i 's/^PermitRootLogin.*/PermitRootLogin no/' $SSH_CONFIG

# Change the default SSH port
sed -i "s/^#Port 22/Port $NEW_SSH_PORT/" $SSH_CONFIG

# Enforce key-based authentication
sed -i 's/^#PubkeyAuthentication yes/PubkeyAuthentication yes/' $SSH_CONFIG
sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication no/' $SSH_CONFIG

# Disable password authentication
sed -i 's/^PasswordAuthentication yes/PasswordAuthentication no/' $SSH_CONFIG

# Restrict SSH access to specific users
echo "AllowUsers $ALLOWED_USERS" >> $SSH_CONFIG

# Additional security settings
echo "Protocol 2" >> $SSH_CONFIG
echo "MaxAuthTries 3" >> $SSH_CONFIG
echo "LoginGraceTime 1m" >> $SSH_CONFIG
echo "PermitEmptyPasswords no" >> $SSH_CONFIG
echo "ClientAliveInterval 300" >> $SSH_CONFIG
echo "ClientAliveCountMax 0" >> $SSH_CONFIG
echo "UseDNS no" >> $SSH_CONFIG

# Restart SSH service to apply changes
systemctl restart sshd

echo "SSH hardening completed successfully."
