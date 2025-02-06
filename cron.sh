#!/bin/bash

# Check if the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Create /etc/cron.allow and add sudoers and root
echo "root" > /etc/cron.allow
getent group sudo | awk -F: '{print $4}' | tr ',' '\n' >> /etc/cron.allow

# Create /etc/cron.deny and deny all other users
awk -F: '{print $1}' /etc/passwd | grep -v -E '^(root|$(getent group sudo | awk -F: '{print $4}' | tr ',' '|'))$' > /etc/cron.deny

# Set permissions on /etc/cron.allow and /etc/cron.deny
chmod 600 /etc/cron.allow /etc/cron.deny

# Set permissions on cron directories and files
chmod 600 /etc/crontab
chmod 700 /etc/cron.d
chmod 700 /var/spool/cron

# Output message
echo "Cron has been hardened. Only sudoers and root can use crontabs."

# Verify the changes
echo "Contents of /etc/cron.allow:"
cat /etc/cron.allow

echo "Contents of /etc/cron.deny:"
cat /etc/cron.deny
