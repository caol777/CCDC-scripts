#!/bin/bash

# Check if the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Variables for IP addresses and ports
VAULT_IP="10.250.128.20"
STORE_IP="10.250.128.44"
ALTITUDE_IP="10.250.128.61"
ECLIPSE_IP="10.250.128.86"
FRUIT_IP="10.250.128.143"
POSTAGE_IP="10.250.128.177"
STOREFRONT_IP="10.250.128.211"
SPECTROSCOPE_IP="10.250.128.224"
GATEWAY_IP="10.250.128.1"
AWS_ARTIFACTS_IP1="10.250.128.2"
AWS_ARTIFACTS_IP2="10.250.128.3"
SOURCE_IP_RANGE="10.250.128.4/24"

# Function to check for errors
check_error() {
    if [ $? -ne 0 ]; then
        echo "Error occurred. Exiting to prevent lockout."
        ufw disable
        exit 1
    fi
}

# Disable IPv6
echo 'IPV6=no' >> /etc/default/ufw
check_error

# Enable UFW
ufw enable
check_error

# Set default policies
ufw default deny incoming
check_error
ufw default allow outgoing
check_error

# Allow specific services and machines
ufw allow from $SOURCE_IP_RANGE to $VAULT_IP port 22  # SSH on vault
check_error
ufw allow from $SOURCE_IP_RANGE to $VAULT_IP port 80  # HTTP on vault
check_error
ufw allow from $SOURCE_IP_RANGE to $STORE_IP port 22  # SSH on store
check_error
ufw allow from $SOURCE_IP_RANGE to $ALTITUDE_IP port 3128  # HTTP on altitude (Port 3128)
check_error
ufw allow from $SOURCE_IP_RANGE to $ALTITUDE_IP port 22  # SSH on altitude
check_error
ufw allow from $SOURCE_IP_RANGE to $ECLIPSE_IP port 3389  # RDP on eclipse
check_error
ufw allow from $SOURCE_IP_RANGE to $ECLIPSE_IP port 389  # LDAP on eclipse
check_error
ufw allow from $SOURCE_IP_RANGE to $ECLIPSE_IP port 53  # DNS on eclipse
check_error
ufw allow from $SOURCE_IP_RANGE to $FRUIT_IP port 22  # SSH on fruit
check_error
ufw allow from $SOURCE_IP_RANGE to $POSTAGE_IP port 3389  # RDP on postage
check_error
ufw allow from $SOURCE_IP_RANGE to $STOREFRONT_IP port 80  # HTTP on storefront
check_error
ufw allow from $SOURCE_IP_RANGE to $STOREFRONT_IP port 3389  # RDP on storefront
check_error
ufw allow from $SOURCE_IP_RANGE to $SPECTROSCOPE_IP port 80  # HTTP on spectroscope
check_error
ufw allow from $SOURCE_IP_RANGE to $SPECTROSCOPE_IP port 22  # SSH on spectroscope
check_error

# Allow off-limits machines
ufw allow from $SOURCE_IP_RANGE to $GATEWAY_IP  # Default Gateway
check_error
ufw allow from $SOURCE_IP_RANGE to $AWS_ARTIFACTS_IP1  # AWS Artifacts
check_error
ufw allow from $SOURCE_IP_RANGE to $AWS_ARTIFACTS_IP2  # AWS Artifacts
check_error

# Enable logging (optional)
ufw logging on
check_error

# Reload UFW to apply changes
ufw reload
check_error

# Check UFW status
ufw status verbose

# Set up a cron job to reload UFW rules every 5 minutes
(crontab -l 2>/dev/null; echo "*/5 * * * * /usr/sbin/ufw reload") | crontab -
