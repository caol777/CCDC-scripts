#!/bin/bash

# Check if the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Enable UFW
ufw enable

# Set default policies
ufw default deny incoming
ufw default allow outgoing

# Allow specific services and machines
ufw allow from 10.250.128.4/24 to 10.250.128.20 port 22  # SSH on vault
ufw allow from 10.250.128.4/24 to 10.250.128.20 port 80  # HTTP on vault
ufw allow from 10.250.128.4/24 to 10.250.128.44 port 22  # SSH on store
ufw allow from 10.250.128.4/24 to 10.250.128.61 port 3128  # HTTP on altitude (Port 3128)
ufw allow from 10.250.128.4/24 to 10.250.128.61 port 22  # SSH on altitude
ufw allow from 10.250.128.4/24 to 10.250.128.86 port 3389  # RDP on eclipse
ufw allow from 10.250.128.4/24 to 10.250.128.86 port 389  # LDAP on eclipse
ufw allow from 10.250.128.4/24 to 10.250.128.86 port 53  # DNS on eclipse
ufw allow from 10.250.128.4/24 to 10.250.128.143 port 22  # SSH on fruit
ufw allow from 10.250.128.4/24 to 10.250.128.177 port 3389  # RDP on postage
ufw allow from 10.250.128.4/24 to 10.250.128.211 port 80  # HTTP on storefront
ufw allow from 10.250.128.4/24 to 10.250.128.211 port 3389  # RDP on storefront
ufw allow from 10.250.128.4/24 to 10.250.128.224 port 80  # HTTP on spectroscope
ufw allow from 10.250.128.4/24 to 10.250.128.224 port 22  # SSH on spectroscope

# Allow off-limits machines
ufw allow from 10.250.128.4/24 to 10.250.128.1  # Default Gateway
ufw allow from 10.250.128.4/24 to 10.250.128.2  # AWS Artifacts
ufw allow from 10.250.128.4/24 to 10.250.128.3  # AWS Artifacts

# Enable logging (optional)
ufw logging on

# Reload UFW to apply changes
ufw reload

# Check UFW status
ufw status verbose
