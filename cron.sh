#!/bin/bash

# Check if the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Set permissions for cron directories and files
chmod 700 /etc/crontab
chmod 700 /etc/cron.d
chmod 700 /etc/cron.daily
chmod 700 /etc/cron.hourly
chmod 700 /etc/cron.monthly
chmod 700 /etc/cron.weekly

# Restrict access to cron.allow and cron.deny
touch /etc/cron.allow
chmod 600 /etc/cron.allow
chown root:root /etc/cron.allow

touch /etc/cron.deny
chmod 600 /etc/cron.deny
chown root:root /etc/cron.deny

# Add authorized users to cron.allow
echo "root" > /etc/cron.allow
# Add other authorized users as needed
# echo "username" >> /etc/cron.allow

# Ensure cron.deny is empty
> /etc/cron.deny

# Disable unnecessary cron services
systemctl disable anacron
systemctl stop anacron

# Restart cron service to apply changes
systemctl restart cron

echo "Cron job hardening completed successfully."
