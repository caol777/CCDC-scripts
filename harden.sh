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

