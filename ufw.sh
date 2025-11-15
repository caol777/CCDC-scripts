#!/bin/bash
# A script to configure UFW (Uncomplicated Firewall)
#
# This will:
# 1. Reset UFW to its default state.
# 2. Set the default policy to DENY incoming traffic.
# 3. Set the default policy to ALLOW outgoing traffic.
# 4. CRITICAL: Allow incoming SSH connections (port 22) to prevent you
#    from being locked out of your server.
#    If you use a different port for SSH, change "ssh" to your port number (e.g., "2222/tcp").
# 5. Deny traffic on port 4444.
# 6. Enable UFW.
# 7. Show the final status.

set -e

echo "Resetting UFW to defaults..."
# --force disables the confirmation prompt
sudo ufw --force reset

echo "Setting default policies..."
# 1. Deny all incoming traffic
sudo ufw default deny incoming

# 2. Allow all outgoing traffic
sudo ufw default allow outgoing

echo "Allowing essential services..."
# IMPORTANT: Allow SSH traffic so you don't get locked out.
# If your SSH port is not 22, change 'ssh' to your port number.
sudo ufw allow ssh
echo "Added rule to allow incoming SSH (port 22)."

echo "Adding custom rules..."
# 3. Deny port 4444
sudo ufw deny 4444
echo "Added rule to deny port 4444."

echo "Enabling UFW..."
# Enable the firewall
sudo ufw enable

echo "UFW configuration complete. Current status:"
# Show the new rules
sudo ufw status verbose
