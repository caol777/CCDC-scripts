#!/bin/bash

# Check if the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Install the required PAM module
if command -v apt-get &> /dev/null; then
    apt-get update
    apt-get install -y libpam-modules
elif command -v yum &> /dev/null; then
    yum install -y pam
else
    echo "Unsupported package manager. Please install pam_tally2 manually."
    exit 1
fi

# Determine the PAM configuration file based on the distribution
if [[ -f /etc/pam.d/common-auth ]]; then
    PAM_FILE="/etc/pam.d/common-auth"
elif [[ -f /etc/pam.d/system-auth ]]; then
    PAM_FILE="/etc/pam.d/system-auth"
else
    echo "PAM configuration file not found. Please check your system."
    exit 1
fi

# Backup the original PAM configuration file
cp "$PAM_FILE" "${PAM_FILE}.bak"

# Add or modify the PAM configuration to enforce user lockout policies
if ! grep -q "pam_tally2.so" "$PAM_FILE"; then
    echo "auth required pam_tally2.so deny=3 unlock_time=600 even_deny_root" >> "$PAM_FILE"
    echo "account required pam_tally2.so" >> "$PAM_FILE"
else
    sed -i 's/.*pam_tally2.so.*/auth required pam_tally2.so deny=3 unlock_time=600 even_deny_root/' "$PAM_FILE"
    sed -i 's/.*pam_tally2.so.*/account required pam_tally2.so/' "$PAM_FILE"
fi

echo "User lockout policy has been updated successfully."

# Display the updated PAM configuration
echo "Updated PAM configuration:"
grep "pam_tally2.so" "$PAM_FILE"
