
#!/bin/bash

# ======== OS Detection Function ========
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        case "$ID" in
            ubuntu)
                opsys="Ubuntu"
                ;;
            linuxmint)
                opsys="Linux Mint"
                ;;
            debian)
                opsys="Debian"
                ;;
            almalinux)
                opsys="AlmaLinux"
                ;;
            centos)
                opsys="CentOS"
                ;;
            rhel)
                opsys="RedHat"
                ;;
            *)
                opsys="Unknown"
                ;;
        esac
    else
        opsys="Unknown"
    fi
    echo "Detected OS: $opsys"
}

# ======== Root Check ========
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi
# ======== File Attribute and Permission Hardening ========
echo "Checking and correcting file attributes and permissions..."

for file in /etc/passwd /etc/shadow /etc/group; do
    if lsattr "$file" | grep -q 'i'; then
        echo "Removing immutable attribute from $file..."
        chattr -i "$file"
    fi

    # Set secure permissions
    case "$file" in
        /etc/passwd|/etc/group)
            chmod 644 "$file"
            ;;
        /etc/shadow)
            chmod 640 "$file"
            ;;
    esac

    echo "Permissions set for $file"
done

echo "File attribute and permission hardening completed."

# ======== SSH Hardening ========
echo "Hardening SSH configuration..."
SSH_CONFIG="/etc/ssh/sshd_config"
cp $SSH_CONFIG ${SSH_CONFIG}.bak

sed -i 's/^#*LoginGraceTime.*/LoginGraceTime 60/' $SSH_CONFIG
sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' $SSH_CONFIG
sed -i 's/^#*Protocol.*/Protocol 2/' $SSH_CONFIG
sed -i 's/^#*PermitEmptyPasswords.*/PermitEmptyPasswords no/' $SSH_CONFIG
sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication yes/' $SSH_CONFIG
sed -i 's/^#*X11Forwarding.*/X11Forwarding no/' $SSH_CONFIG
sed -i 's/^#*MaxAuthTries.*/MaxAuthTries 2/' $SSH_CONFIG
sed -i 's/^#*MaxSessions.*/MaxSessions 2/' $SSH_CONFIG
sed -i 's/^#*AllowTcpForwarding.*/AllowTcpForwarding no/' $SSH_CONFIG


systemctl restart sshd
echo "SSH hardening completed."


# ======== Login Definitions Hardening ========
echo "Hardening login definitions..."

LOGIN_DEFS="/etc/login.defs"
cp $LOGIN_DEFS ${LOGIN_DEFS}.bak

# Set PASS_MAX_DAYS to 30
sed -i 's/^\s*PASS_MAX_DAYS\s\+[0-9]\+/PASS_MAX_DAYS\t30/' $LOGIN_DEFS

# Set PASS_MIN_DAYS to 10
sed -i 's/^\s*PASS_MIN_DAYS\s\+[0-9]\+/PASS_MIN_DAYS\t10/' $LOGIN_DEFS

# Set PASS_WARN_AGE to 7
sed -i 's/^\s*PASS_WARN_AGE\s\+[0-9]\+/PASS_WARN_AGE\t7/' $LOGIN_DEFS

# Set login retry limit
sed -i 's/^\s*LOGIN_RETRIES\s\+[0-9]\+/LOGIN_RETRIES\t3/' $LOGIN_DEFS

# ======== System-Specific Hardening ========
detect_os

case "$opsys" in
    "Linux Mint"|"Ubuntu"|"Debian")
        echo "APT-based system detected: $opsys"
        apt-get update -y
        apt-get upgrade -y
        apt-get dist-upgrade -y
        killall firefox 2>/dev/null
        apt-get --purge --reinstall install firefox -y
        apt-get install clamtk vsftpd ntp -y

        # FTP Hardening
        cat <<EOL >> /etc/vsftpd.conf
anonymous_enable=NO
local_enable=YES
write_enable=NO
chroot_local_user=YES
allow_writeable_chroot=YES
EOL
        systemctl restart vsftpd

        # NTP Hardening
        cat <<EOL >> /etc/ntp.conf
restrict default nomodify notrap nopeer noquery
restrict 127.0.0.1
restrict <trusted-ntp-server-ip> nomodify notrap
EOL
        systemctl restart ntp
        ;;

    "AlmaLinux"|"RedHat"|"CentOS")
        echo "YUM/DNF-based system detected: $opsys"
        if command -v dnf &> /dev/null; then
            dnf update -y
            dnf upgrade -y
            dnf reinstall firefox -y
            dnf install clamtk bind bind-utils -y
        else
            yum update -y
            yum upgrade -y
            yum reinstall firefox -y
            yum install clamtk bind bind-utils -y
        fi
        # DNS Hardening
        cat <<EOL >> /etc/named.conf
options {
    directory "/var/named";
    allow-transfer { none; };
    allow-query { any; };
};
EOL
        systemctl restart named

        # WordPress Hardening
        echo "Hardening WordPress..."
        chown -R wp-user:www-data /var/www/html/
        find /var/www/html/ -type d -exec chmod 755 {} \;
        find /var/www/html/ -type f -exec chmod 644 {} \;
        chmod 600 /var/www/html/wp-config.php
        ;;

    *)
        echo "Unsupported or unknown OS: $opsys"
        exit 1
        ;;
esac

# ======== Kernel Hardening (Moved to Bottom) ========
echo "Starting kernel hardening..."
KERNEL_CONF="/etc/sysctl.conf"
cp $KERNEL_CONF ${KERNEL_CONF}.bak

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
net.ipv4.ip_forward = 0
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv.disable_ipv6 = 1
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

sysctl -p >/dev/null
echo "Kernel hardening completed."

echo "✅ System hardening completed successfully."
