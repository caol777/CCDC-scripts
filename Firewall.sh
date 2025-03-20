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

# Function to apply firewall rules
apply_firewall_rules() {
    # Flush the current rules
    echo "[+] Flushing iptables rules..."
    $ipt -F; $ipt -X
    $ipt -t nat -F
    $ipt -t nat -X
    $ipt -t mangle -F
    $ipt -t mangle -X

    # Set default policies
    echo "[+] Setting default policies (DROP incoming, DROP forwarding, ALLOW outgoing)..."
    $ipt -P INPUT DROP
    $ipt -P FORWARD DROP
    $ipt -P OUTPUT ACCEPT

    # Allow loopback interface traffic
    echo "[+] Allowing loopback interface traffic..."
    $ipt -A INPUT -i lo -j ACCEPT

    # Allow established and related incoming traffic
    echo "[+] Allowing established and related incoming traffic..."
    $ipt -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

    # Allow services in. We want SSH (22), FTP (21), and NTP (123)
    echo "[+] Allowing incoming TCP on the specified ports: 22 (SSH), 21 (FTP), 123 (NTP)"
    $ipt -A INPUT -p tcp -m multiport --dport 22,21 -j ACCEPT
    $ipt -A INPUT -p udp --dport 123 -j ACCEPT

    # Rate limiting for SSH
    echo "[+] Adding rate limiting for SSH..."
    $ipt -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW -m recent --set
    $ipt -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW -m recent --update --seconds 60 --hitcount 5 -j DROP

    # Logging dropped packets
    echo "[+] Adding logging for dropped packets..."
    $ipt -A INPUT -j LOG --log-prefix "IPTables-Dropped: " --log-level 4

    echo "[+] Firewall rules applied."
}

# Loop to continuously apply firewall rules
while true; do
    apply_firewall_rules
    echo "[+] Sleeping for 30 seconds..."
    sleep 30
done
