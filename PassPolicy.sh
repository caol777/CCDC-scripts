#!/bin/bash

# Check if the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Install the required PAM module
if command -v apt-get &> /dev/null; then
    apt-get update
    apt-get install -y libpam-pwquality
elif command -v yum &> /dev/null; then
    yum install -y libpwquality
else
    echo "Unsupported package manager. Please install libpam-pwquality manually."
    exit 1
fi

# Determine the PAM configuration file based on the distribution
if [[ -f /etc/pam.d/common-password ]]; then
    PAM_FILE="/etc/pam.d/common-password"
elif [[ -f /etc/pam.d/system-auth ]]; then
    PAM_FILE="/etc/pam.d/system-auth"
else
    echo "PAM configuration file not found. Please check your system."
    exit 1
fi

# Backup the original PAM configuration file
cp "$PAM_FILE" "${PAM_FILE}.bak"

# Add or modify the PAM configuration to enforce password policies
if grep -q "pam_pwquality.so" "$PAM_FILE"; then
    sed -i 's/.*pam_pwquality.so.*/password requisite pam_pwquality.so retry=3 minlen=10 ucredit=-1 lcredit=-1 dcredit=-1 ocredit=-1/' "$PAM_FILE"
else
    echo "password requisite pam_pwquality.so retry=3 minlen=16 ucredit=-1 lcredit=-1 dcredit=-1 ocredit=-1" >> "$PAM_FILE"
fi

echo "Password policy has been updated successfully."

# Display the updated PAM configuration
echo "Updated PAM configuration:"
grep "pam_pwquality.so" "$PAM_FILE"
