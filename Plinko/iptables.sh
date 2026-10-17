#!/usr/bin/env bash
#
# fw-allowlist.sh - interactive default-deny iptables baseline for Horse Plinko / CCDC boxes.
#
# What it does:
#   * flushes existing rules (wipes anything Red Team planted)
#   * default-deny inbound + forward, allow outbound
#   * always keeps loopback + established/related connections
#   * PROMPTS you for the TCP ports to allow, then opens each one to any source
#   * persists the rules so a reboot/flush doesn't lose them
#
# Run as root:   sudo ./fw-allowlist.sh
# Or pass ports non-interactively:   sudo ./fw-allowlist.sh 22 80 443 8080
#
# !! INCLUDE SSH (22) AND EVERY SCORED PORT or you will lock out yourself/scoring !!
#    Scoring hits from many IPs, so scored ports are opened to ANY source on purpose.
#
# Fedora note (ignition): Fedora uses firewalld, which clashes with raw iptables.
#    Stop it first:  sudo systemctl stop firewalld   (then run this)
#    or use firewalld instead:  sudo firewall-cmd --permanent --add-port=80/tcp ; sudo firewall-cmd --reload

set -u

# --- must be root ---
if [ "$(id -u)" -ne 0 ]; then
  echo "[!] Run as root (sudo $0)"; exit 1
fi

# --- pick iptables binary (handles nft-backed systems) ---
IPT="$(command -v iptables || true)"
if [ -z "$IPT" ]; then
  echo "[!] iptables not found. On Fedora try: sudo dnf install -y iptables-services"
  exit 1
fi

# --- get the ports: from args, or prompt ---
if [ "$#" -gt 0 ]; then
  PORTS="$*"
else
  echo "[*] Enter the TCP ports to ALLOW inbound, space-separated."
  echo "    Include 22 (SSH) and every scored port. Examples:"
  echo "      guidance/ignition web:  22 80 443 8080"
  echo "      with extra services:    22 80 443 8080 3306"
  read -rp "Ports: " PORTS
fi

# --- validate input: only numbers 1-65535 ---
VALID=""
for p in $PORTS; do
  if [[ "$p" =~ ^[0-9]+$ ]] && [ "$p" -ge 1 ] && [ "$p" -le 65535 ]; then
    VALID="$VALID $p"
  else
    echo "[!] Skipping invalid port: '$p'"
  fi
done
if [ -z "${VALID// /}" ]; then
  echo "[!] No valid ports given. Aborting so you don't lock yourself out."
  exit 1
fi

# --- safety check: warn if SSH (22) is missing ---
case " $VALID " in
  *" 22 "*) : ;;
  *) echo "[!] WARNING: port 22 (SSH) is NOT in your list. You may lose remote access."
     read -rp "    Continue anyway? [y/N] " ok
     [[ "$ok" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 1; } ;;
esac

echo "[*] Flushing existing rules..."
$IPT -F
$IPT -X 2>/dev/null || true

echo "[*] Setting default policy: INPUT/FORWARD DROP, OUTPUT ACCEPT..."
$IPT -P INPUT DROP
$IPT -P FORWARD DROP
$IPT -P OUTPUT ACCEPT

echo "[*] Allowing loopback, established/related, and ICMP..."
$IPT -A INPUT -i lo -j ACCEPT
$IPT -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
$IPT -A INPUT -p icmp -j ACCEPT

echo "[*] Opening requested ports (to any source, for scoring)..."
for p in $VALID; do
  $IPT -A INPUT -p tcp --dport "$p" -j ACCEPT
  echo "    [+] allowed tcp/$p"
done

echo
echo "[*] Current INPUT chain:"
$IPT -L INPUT -n --line-numbers

# --- persist ---
echo
echo "[*] Saving rules so a reboot/flush doesn't wipe them..."
if command -v netfilter-persistent >/dev/null 2>&1; then
  netfilter-persistent save && echo "    saved via netfilter-persistent (Ubuntu/Mint)"
elif [ -d /etc/sysconfig ]; then
  iptables-save > /etc/sysconfig/iptables && echo "    saved to /etc/sysconfig/iptables (Fedora/RHEL)"
else
  iptables-save > /etc/iptables.rules
  echo "    saved to /etc/iptables.rules"
  echo "    restore after reboot with:  iptables-restore < /etc/iptables.rules"
fi

echo
echo "[OK] Firewall baseline applied."
echo "[>] NOW VERIFY: make sure jmoney can still SSH in and your scored services are still green."
