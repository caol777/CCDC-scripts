#!/bin/sh
BLACK_TEAM_IP="192.168.122.11"

# CHANGE THIS FOR YOUR NETWORK
INT_NET="192.168.122.0/24"

# CHANGE THIS PER MACHINE
EXT_IF="enp1s0"
ALLOW_TCP_INBOUND="22 80 443"
ALLOW_TCP_OUTBOUND="88 389 443 636"

# Flush existing rules (CAREFUL! This clears all existing firewall rules)
iptables -F
iptables -X

# state tracking rules (linux firewalls book)
iptables -A INPUT -m state --state INVALID -j LOG --log-prefix "DROP INVALID " --log-ip-options --log-tcp-options
iptables -A INPUT -m state --state INVALID -j DROP
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -m conntrack --ctstate ESTABLISHED -j ACCEPT

# anti-spoofing rules (linux firewalls book)
#iptables -A INPUT -i $EXT_IF -s ! $INT_NET -j LOG --log-prefix "SPOOFED PKT "
#iptables -A INPUT -i $EXT_IF -s ! $INT_NET -j DROP

# Whitelist Internal Network (add rules *before* the default DROP)
# seems weird to have this in CCDC when red team can attack us from internal net
#iptables -A INPUT -s $INT_NET -j ACCEPT
#iptables -A OUTPUT -d $INT_NET -j ACCEPT

# Default policies (drop everything)
iptables -P INPUT DROP
#iptables -P FORWARD DROP
#iptables -P OUTPUT DROP

# Allow loopback traffic
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# allow regular pings
iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT
iptables -A OUTPUT -p icmp --icmp-type echo-request -j ACCEPT

# Allow specific services (replace with your services and ports)
for port in $ALLOW_TCP_INBOUND; do
    iptables -A INPUT -p tcp --dport $port -j ACCEPT
done

for port in $ALLOW_UDP_INBOUND; do
    iptables -A INPUT -p udp --dport $port -j ACCEPT
done

for port in $ALLOW_TCP_OUTBOUND; do
    iptables -A OUTPUT -p tcp --sport $port -j ACCEPT
done

for port in $ALLOW_UDP_OUTBOUND; do
    iptables -A OUTPUT -p udp --sport $port -j ACCEPT
done

# Whitelist Black Team (add rules *before* the default DROP)
for ip in $BLACKTEAM_IPS; do
  iptables -A INPUT -s $ip -j ACCEPT
  iptables -A OUTPUT -d $ip -j ACCEPT
done

# Log dropped packets (optional - can be noisy)
iptables -A INPUT -j LOG --log-prefix "iptables-dropped: "
iptables -A OUTPUT -j LOG --log-prefix "iptables-dropped: "

echo "Basic firewall configured."
# To make these rules persistent after a reboot, you'll need
# to save them.  The method varies by distribution:
#  - Debian/Ubuntu:  iptables-save > /etc/iptables/rules.v4
#  - CentOS/RHEL:    iptables-save > /etc/sysconfig/iptables
