#!/bin/bash

# Check if the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

echo "Starting PAM security configuration..."

# ======== Install Required PAM Modules ========
echo "Installing required PAM modules..."

# Determine the package manager and install required PAM modules
if command -v apt-get &> /dev/null; then
    # Debian-based systems (Ubuntu, Debian, etc.)
    echo "Detected Debian-based system. Installing PAM modules..."
    apt-get update
    apt-get install -y libpam-pwquality libpam-modules
elif command -v yum &> /dev/null; then
    # CentOS, Red Hat Linux
    echo "Detected CentOS/Red Hat system. Installing PAM modules..."
    yum install -y libpwquality pam
elif command -v pacman &> /dev/null; then
    # Arch Linux
    echo "Detected Arch Linux system. Installing PAM modules..."
    pacman -S --noconfirm pam libpwquality
else
    echo "Unsupported package manager. Please install the required PAM modules manually."
    exit 1
fi

# ======== Configure User Lockout Policy ========
echo "Configuring user lockout policy..."

# Determine the PAM authentication configuration file
if [[ -f /etc/pam.d/common-auth ]]; then
    # Debian-based systems
    PAM_AUTH_FILE="/etc/pam.d/common-auth"
elif [[ -f /etc/pam.d/system-auth ]]; then
    # CentOS, Red Hat, Arch Linux
    PAM_AUTH_FILE="/etc/pam.d/system-auth"
else
    echo "Lockout policy PAM configuration file not found. Please check your system."
    exit 1
fi

# Backup the original authentication policy file
cp "$PAM_AUTH_FILE" "${PAM_AUTH_FILE}.bak"

# Enforce account lockout policy
if ! grep -q "pam_tally2.so" "$PAM_AUTH_FILE"; then
    # Add pam_tally2.so lines if they don't exist
    echo "auth required pam_tally2.so deny=3 unlock_time=600 even_deny_root" >> "$PAM_AUTH_FILE"
    echo "account required pam_tally2.so" >> "$PAM_AUTH_FILE"
else
    # Update existing pam_tally2.so lines
    sed -i 's/.*pam_tally2.so.*/auth required pam_tally2.so deny=3 unlock_time=600 even_deny_root/' "$PAM_AUTH_FILE"
    sed -i 's/.*pam_tally2.so.*/account required pam_tally2.so/' "$PAM_AUTH_FILE"
fi

echo "User lockout policy updated successfully."
echo "Updated Lockout Policy Configuration:"
grep "pam_tally2.so" "$PAM_AUTH_FILE"

echo "PAM security configuration completed successfully."
