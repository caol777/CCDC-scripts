export DISPATCHER="192.168.1.50"      # Your management/Blue Team IP
export LOCALNETWORK="192.168.1.0/24"   # Your internal team subnet
export CCSHOST="192.168.220.70"       # The IP of the scoring engine/NAT router


# Temporarily allow outgoing web traffic to download tools
iptables -A OUTPUT -p tcp -m multiport --dports 80,443 -j ACCEPT
