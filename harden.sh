#!/bin/bash

# ======== PART 1: Kernel Hardening ========
echo "Starting kernel hardening..."

# File to store kernel parameters
KERNEL_CONF="/etc/sysctl.conf"

# Backup the original sysctl.conf file
cp $KERNEL_CONF ${KERNEL_CONF}.bak

# Append kernel hardening parameters to sysctl.conf
cat <<EOL >> $KERNEL_CONF
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_challenge_ack_limit = 1000000
net.ipv4.tcp_rfc1337 = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.icmp_echo_ignore_all = 1
kernel.core_uses_pid = 1
kernel.kptr_restrict = 2
kernel.modules_disabled = 1
kernel.perf_event_paranoid = 2
kernel.randomize_va_space = 2
kernel.sysrq = 0
kernel.yama.ptrace_scope = 2
fs.protected_hardlinks = 1
fs.protected_symlinks = 1
fs.suid_dumpable = 0
kernel.unprivileged_userns_clone = 0
fs.protected_fifos = 2
fs.protected_regular = 2
EOL

# Apply kernel parameters
sysctl -p >/dev/null

echo "Kernel hardening completed."

# ======== PART 2: Cron Job Hardening ========
echo "Starting cron job hardening..."

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
cat <<EOL > /etc/cron.allow
root
jeremy.rover
maxwell.starling
jack.harris
emily.chen
william.wilson
melissa.chen
john.taylor
laura.harris
alan.chen
anna.wilson
matthew.taylor
EOL

# Ensure cron.deny is empty
> /etc/cron.deny

# Disable unnecessary cron services
systemctl disable anacron
systemctl stop anacron

# Restart cron service to apply changes
systemctl restart cron

echo "Cron job hardening completed."

# ======== PART 3: SSH Hardening ========
echo "Starting SSH hardening..."

# Variables
SSH_CONFIG="/etc/ssh/sshd_config"
NEW_SSH_PORT=2222
ALLOWED_USERS="seccdc_black postgres root jeremy.rover maxwell.starling jack.harris emily.chen william.wilson melissa.chen john.taylor laura.harris alan.chen anna.wilson matthew.taylor"

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
cat <<EOL >> $SSH_CONFIG
Protocol 2
MaxAuthTries 3
LoginGraceTime 1m
PermitEmptyPasswords no
ClientAliveInterval 300
ClientAliveCountMax 0
X11Forwarding no
UseDNS no
PasswordAuthentication no
AllowTcpFowarding no
EOL

# Restart SSH service to apply changes
systemctl restart sshd

echo "SSH hardening completed."

# ======== Final Message ========
echo "System hardening completed successfully."
