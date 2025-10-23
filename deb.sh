#!/bin/bash


passwd -l root

# Determine the package manager
if command -v apt > /dev/null; then
    pkgManager="apt"
elif command -v dnf > /dev/null; then
    pkgManager="dnf"
elif command -v yum > /dev/null; then
    pkgManager="yum"
else
    echo "No known package manager found. Script will exit."
    exit 1
fi

echo "Using package manager: $pkgManager"

# Define a generic update, install, and remove function
update_system() {
    sudo $pkgManager update -y
    if [ "$pkgManager" = "apt" ]; then
        sudo $pkgManager upgrade -y
    fi
}

install_package() {
    for pkg in "$@"; do
        echo "Attempting to install $pkg..."
        sudo $pkgManager install -y "$pkg" || echo "Failed to install $pkg. Skipping..."
    done
}

remove_package() {
    if [ "$pkgManager" = "apt" ]; then
        sudo $pkgManager purge -y "$@"
    else
        sudo $pkgManager remove -y "$@"
    fi
}

fix_missing_apt() {
    if [ "$pkgManager" = "apt" ]; then
        sudo apt update --fix-missing
    fi
}

enable_service() {
    sudo systemctl enable "$@"
    sudo systemctl start "$@"
}

fix_missing_apt

# Update system
update_system

# Install packages
# Added iptables-persistent and iptables-services to the package list
packageList="inotify-tools rsyslog git fail2ban zip tmux net-tools htop tcpdump e2fsprogs nmap ufw rkhunter whowatch curl debsums chkrootkit clamav clamav-daemon"
install_package $packageList

wget https://github.com/DominicBreuker/pspy/releases/download/v1.2.1/pspy64
chmod +x pspy64
wget https://github.com/peass-ng/PEASS-ng/releases/latest/download/linpeas.sh
chmod +x linpeas.sh

remove_package cron

# Special handling for UFW, considering its availability
# Removed the UFW installation from here because it's now included directly in the package list

# Enable and start fail2ban
enable_service fail2ban
enable_service clamav-freshclam
echo "Package installation and configuration completed."





echo "PermitRootLogin no" >> /etc/ssh/sshd_config
echo "Protocol 2" >> /etc/ssh/sshd_config
#SSH whitelist

systemctl restart sshd

apt install ufw -y
#metasploit default port
ufw deny 4444


ufw default deny incoming
ufw default allow outgoing
#sets firewall rules
ufw allow OpenSSH
ufw allow Bind9
ufw allow 53 tcp
ufw enable

chmod 644 /etc/passwd

pwck
sudo scp -r /etc/bind plinktern@172.16.17.5:~/
sudo scp -r /etc/ssh/sshd_config plinktern@172.16.17.5:~/

chattr +i /etc/bind
chattr +i /etc/ssh/sshd_config
sudo chattr +i ~/.bashrc
sudo chattr +i /home/jmoney/.bashrc
sudo chattr +i /home/plinktern/.bashrc

