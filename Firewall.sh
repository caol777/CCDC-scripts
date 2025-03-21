#!/bin/bash

# Check if the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Exit if any errors occur
set -e

# Define iptables command
ipt="iptables"

# Function to disable IPv6
disable_ipv6() {
    echo "[+] Disabling IPv6..."

    # For Ubuntu
    if [[ -f /etc/lsb-release ]]; then
        echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
        echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf
        echo "net.ipv6.conf.lo.disable_ipv6 = 1" >> /etc/sysctl.conf
        sysctl -p
        echo "[+] IPv6 disabled on Ubuntu."

    # For CentOS
    elif [[ -f /etc/centos-release ]]; then
        echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
        echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf
        echo "net.ipv6.conf.lo.disable_ipv6 = 1" >> /etc/sysctl.conf
        sysctl -p
        echo "[+] IPv6 disabled on CentOS."
    fi
}

# Function to apply firewall rules for CentOS
apply_centos_firewall_rules() {
    echo "[+] Flushing iptables rules..."
    $ipt -F; $ipt -X
    $ipt -t nat -F
    $ipt -t nat -X
    $ipt -t mangle -F
    $ipt -t mangle -X

    echo "[+] Setting default policies (DROP incoming, DROP forwarding, ALLOW outgoing)..."
    $ipt -P INPUT DROP
    $ipt -P FORWARD DROP
    $ipt -P OUTPUT ACCEPT

    echo "[+] Allowing loopback interface traffic..."
    $ipt -A INPUT -i lo -j ACCEPT

    echo "[+] Allowing established and related incoming traffic..."
    $ipt -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

    echo "[+] Allowing incoming TCP on the specified ports: 53 (DNS), 443 (HTTPS)"
    $ipt -A INPUT -p tcp --dport 443 -j ACCEPT
    $ipt -A INPUT -p udp --dport 53 -j ACCEPT

    echo "[+] Adding logging for dropped packets..."
    $ipt -A INPUT -j LOG --log-prefix "IPTables-Dropped: " --log-level 4

    echo "[+] CentOS firewall rules applied."
}

# Function to apply firewall rules for Ubuntu
apply_ubuntu_firewall_rules() {
    echo "[+] Flushing iptables rules..."
    $ipt -F; $ipt -X
    $ipt -t nat -F
    $ipt -t nat -X
    $ipt -t mangle -F
    $ipt -t mangle -X

    echo "[+] Setting default policies (DROP incoming, DROP forwarding, ALLOW outgoing)..."
    $ipt -P INPUT DROP
    $ipt -P FORWARD DROP
    $ipt -P OUTPUT ACCEPT

    echo "[+] Allowing loopback interface traffic..."
    $ipt -A INPUT -i lo -j ACCEPT

    echo "[+] Allowing established and related incoming traffic..."
    $ipt -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

    echo "[+] Allowing incoming TCP on the specified ports: 21 (FTP), 123 (NTP)"
    $ipt -A INPUT -p tcp --dport 21 -j ACCEPT
    $ipt -A INPUT -p udp --dport 123 -j ACCEPT

    echo "[+] Adding logging for dropped packets..."
    $ipt -A INPUT -j LOG --log-prefix "IPTables-Dropped: " --log-level 4

    echo "[+] Ubuntu firewall rules applied."
}

# Disable IPv6
disable_ipv6

# Check the OS and apply the appropriate firewall rules
if [[ -f /etc/centos-release ]]; then
    echo "[+] Detected CentOS."
    apply_centos_firewall_rules
elif [[ -f /etc/lsb-release ]]; then
    echo "[+] Detected Ubuntu."
    apply_ubuntu_firewall_rules
else
    echo "Unsupported operating system."
    exit 1
fi

# Loop to continuously apply firewall rules
while true;
