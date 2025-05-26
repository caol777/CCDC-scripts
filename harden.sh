#!/bin/bash

# Check if the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

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
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.icmp_echo_ignore_all = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.all.disable_ipv6 = 1
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
kernel.exec-shield = 1
EOL
# Apply kernel parameters
sysctl -p >/dev/null

echo "Kernel hardening completed."

# ======== PART 2: System Check and Service Hardening ========
echo "Checking system type..."

if [[ -f /etc/centos-release ]]; then
    # CentOS 7 specific commands
    echo "Detected CentOS 7."


    # Hardening DNS
    echo "Configuring DNS (BIND)..."
    yum install -y bind bind-utils
    cat <<EOL >> /etc/named.conf
options {
    directory "/var/named";
    allow-transfer { none; };
    allow-query { any; };
};
EOL
    systemctl restart named

    # Hardening WordPress
    echo "Hardening WordPress..."
    # Assuming WordPress is installed in /var/www/html
    chown -R wp-user:www-data /var/www/html/
    find /var/www/html/ -type d -exec chmod 755 {} \;
    find /var/www/html/ -type f -exec chmod 644 {} \;
    chmod 600 /var/www/html/wp-config.php

elif [[ -f /etc/os-release ]]; then
    # Ubuntu 22.04 specific commands
    echo "Detected Ubuntu 22.04."

    # Hardening FTP
    echo "Configuring FTP (vsftpd)..."
    apt-get install -y vsftpd
    cat <<EOL >> /etc/vsftpd.conf
anonymous_enable=NO
local_enable=YES
write_enable=NO
chroot_local_user=YES
allow_writeable_chroot=YES
EOL
    systemctl restart vsftpd

    # Hardening NTP
    echo "Configuring NTP..."
    apt-get install -y ntp
    cat <<EOL >> /etc/ntp.conf
restrict default nomodify notrap nopeer noquery
restrict 127.0.0.1
restrict <trusted-ntp-server-ip> nomodify notrap
EOL
    systemctl restart ntp
else
    echo "Unsupported operating system."
    exit 1
fi

# Final message indicating completion
echo "System hardening completed successfully."
