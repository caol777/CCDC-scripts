#!/bin/bash

# --- CONFIGURATION ---
# !!! IMPORTANT: Ensure these users exist on your system before running! !!!
SSH_ALLOWED_USERS="jmomey plinktern"

# --- SCRIPT START ---

# Exit immediately if a command exits with a non-zero status.
set -e

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root. Please use sudo." >&2
  exit 1
fi

echo "--- Starting System Update (using DNF) ---"
dnf update -y
dnf upgrade -y
dnf autoremove -y

echo "--- Installing Required Packages ---"
# Install EPEL repository for packages like rkhunter
dnf install -y epel-release

# Adjusted package list for AlmaLinux
packageList="inotify-tools rsyslog git fail2ban zip tmux net-tools htop e2fsprogs tcpdump firewalld rkhunter whowatch curl chkrootkit clamav clamav-daemon"

for pkg in $packageList; do
    echo "Attempting to install $pkg..."
    dnf install -y "$pkg" || echo "Failed to install $pkg. Skipping..."
done

echo "--- Downloading pspy64 ---"
# Download to a standard location for system-wide executables
wget -O /usr/local/bin/pspy64 https://github.com/DominicBreuker/pspy/releases/download/v1.2.1/pspy64
chmod +x /usr/local/bin/pspy64

# DANGER: This removes the system's task scheduler. Comment this out if unsure.
echo "Removing cronie package..."
# dnf remove -y cronie

echo "--- Securing System and SSH ---"

# Lock the root user's password for security
echo "Locking root account password..."
passwd -l root

# Configure SSH securely using sed to prevent duplicate entries
echo "Configuring sshd_config..."
sed -i '/^PermitRootLogin/c\PermitRootLogin no' /etc/ssh/sshd_config
sed -i '/^Protocol/c\Protocol 2' /etc/ssh/sshd_config

# Remove any existing AllowUsers line and add the new one
sed -i '/^AllowUsers/d' /etc/ssh/sshd_config
echo "AllowUsers $SSH_ALLOWED_USERS" >> /etc/ssh/sshd_config

# Restart SSH to apply changes
echo "Restarting SSH service..."
systemctl restart sshd

echo "--- Enabling Services ---"
systemctl enable --now fail2ban

echo "--- Configuring Firewall (firewalld) ---"
# Start and enable firewalld
systemctl enable --now firewalld

# Add permanent rules for allowed services
echo "Adding firewall rules..."
firewall-cmd --permanent --add-service=ssh
 
# Explicitly deny Metasploit default port with a "reject" action
firewall-cmd --permanent --add-rich-rule='rule port protocol="tcp" port="4444" reject'

# Reload the firewall to apply the permanent rules
echo "Reloading firewall..."
firewall-cmd --reload

echo "--- Setting Secure Permissions & File Integrity ---"
chmod 644 /etc/passwd
pwck # Check password file integrit

sudo scp -r /etc/httpd/ plinktern@172.16.17.5:~/
sudo scp -r /var/www/html/ plinktern@172.16.17.5:~/



sudo chown -R root:root /etc/httpd
chattr +i /var/www/html/
chattr +i /etc/ssh/sshd_config

echo "--- Security Hardening Script Finished ---"
echo "Current firewall configuration:"
firewall-cmd --list-all
