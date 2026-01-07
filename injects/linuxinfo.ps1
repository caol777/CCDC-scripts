#!/usr/bin/env bash
set -euo pipefail

HOST="$(hostname -s 2>/dev/null || hostname)"
TS="$(date +%F_%H%M%S)"

OUTDIR="Inventory_${HOST}_${TS}"
OUTFILE="${OUTDIR}/inventory.txt"

mkdir -p "$OUTDIR"

add() { printf "%s\n" "$*" >> "$OUTFILE"; }

# ---- OS Info ----
OS_PRETTY="(Unable to read OS info)"
if [[ -f /etc/os-release ]]; then
  # shellcheck disable=SC1091
  . /etc/os-release
  OS_PRETTY="${PRETTY_NAME:-$NAME}"
fi
KERNEL="$(uname -r 2>/dev/null || echo unknown)"

# ---- IPs (IPv4) ----
get_ips() {
  if command -v ip >/dev/null 2>&1; then
    # interface + IPv4 (no loopback)
    ip -br -4 addr show | awk '$1!="lo" {print $1": "$3}' | sed 's#/.*##'
  else
    # fallback
    ifconfig 2>/dev/null | awk '
      $1 ~ /flags=/ {iface=$1; gsub(":", "", iface)}
      $1=="inet" && $2!="127.0.0.1" {print iface": "$2}
    ' || true
  fi
}

# ---- Listening ports with process evidence ----
# Prefer ss; fallback to netstat
get_listeners() {
  if command -v ss >/dev/null 2>&1; then
    # ss output: proto local_address:port users:(("proc",pid=123,fd=...))
    ss -H -lntup 2>/dev/null || true
  elif command -v netstat >/dev/null 2>&1; then
    netstat -lntup 2>/dev/null || true
  else
    return 0
  fi
}

# Parse ss -> rows: proto port pid proc
parse_ss() {
  # ss -H -lntup
  # Example fields: tcp LISTEN 0 128 0.0.0.0:22 0.0.0.0:* users:(("sshd",pid=123,fd=3))
  awk '
    {
      proto=$1
      local=$4
      # port is after last colon (handles [::]:443 too)
      gsub(/.*:/,"",local)
      port=local

      pid=""; proc=""
      if (match($0, /users:\(\("([^"]+)",pid=([0-9]+)/, m)) {
        proc=m[1]; pid=m[2]
      }
      if (port ~ /^[0-9]+$/) {
        print proto, port, pid, proc
      }
    }
  ' 
}

# Parse netstat -> rows: proto port pid proc
parse_netstat() {
  # netstat -lntup: Proto Recv-Q Send-Q Local Address Foreign Address State PID/Program name
  awk '
    NR>2 {
      proto=$1
      local=$4
      gsub(/.*:/,"",local); port=local
      pidproc=$7
      pid=""; proc=""
      if (pidproc ~ /[0-9]+\//) {
        split(pidproc,a,"/"); pid=a[1]; proc=a[2]
      }
      if (port ~ /^[0-9]+$/) {
        print proto, port, pid, proc
      }
    }
  '
}

# Normalize proto to tcp/udp
norm_proto() {
  case "$1" in
    tcp|tcp6) echo "tcp" ;;
    udp|udp6) echo "udp" ;;
    *) echo "$1" ;;
  esac
}

# ---- Port map (same “friend-style” labels) ----
service_label() {
  local port="$1"
  case "$port" in
    22)   echo "Remote (ssh)" ;;
    80)   echo "HTTP" ;;
    443)  echo "HTTPS" ;;
    3389) echo "Remote (rdp)" ;;
    445)  echo "File Share (smb)" ;;
    135)  echo "RPC" ;;
    53)   echo "DNS" ;;
    389)  echo "Domain Controller (ldap)" ;;
    636)  echo "Domain Controller (ldaps)" ;;
    88)   echo "Domain Controller (kerberos)" ;;
    1433) echo "Database (mssql)" ;;
    3306) echo "Database (mysql)" ;;
    5432) echo "Database (postgres)" ;;
    25)   echo "Mail (smtp)" ;;
    110)  echo "Mail (pop3)" ;;
    143)  echo "Mail (imap)" ;;
    587)  echo "Mail (submission)" ;;
    *)    echo "" ;;
  esac
}

# ---- Write report header ----
: > "$OUTFILE"
add "Inventory Report"
add "Generated: $(date)"
add ""
add "Host:"
add "  $HOST"
add ""
add "Operating System:"
add "  $OS_PRETTY (Kernel $KERNEL)"
add ""
add "IP Addresses (IPv4):"
IPS="$(get_ips || true)"
if [[ -n "${IPS// }" ]]; then
  while IFS= read -r line; do
    [[ -n "$line" ]] && add "  $line"
  done <<< "$IPS"
else
  add "  (none found)"
fi
add ""

# ---- Collect listeners (evidence rows) ----
RAW="$(get_listeners || true)"

ROWS=""
if [[ -n "${RAW// }" ]]; then
  if command -v ss >/dev/null 2>&1; then
    ROWS="$(printf "%s\n" "$RAW" | parse_ss)"
  else
    ROWS="$(printf "%s\n" "$RAW" | parse_netstat)"
  fi
fi

# Build sets for mapped/unmapped + services list
declare -A seen_mapped
declare -A seen_unmapped
declare -A seen_services

if [[ -n "${ROWS// }" ]]; then
  while read -r proto port pid proc; do
    [[ -z "${port:-}" ]] && continue
    p="$(norm_proto "$proto")"
    label="$(service_label "$port")"

    if [[ -n "$label" ]]; then
      seen_services["$label"]=1
      seen_mapped["${port}/${p}"]="$label"
    else
      seen_unmapped["${port}/${p}"]=1
    fi
  done <<< "$ROWS"
fi

# ---- Services (friend-style line) ----
add "Services (inferred from listening ports):"
if [[ "${#seen_services[@]}" -gt 0 ]]; then
  # print sorted services
  printf "%s\n" "${!seen_services[@]}" | sort | while read -r svc; do :; done >/dev/null
  svc_line="$(printf "%s\n" "${!seen_services[@]}" | sort | paste -sd ", " -)"
  add "  $svc_line"
else
  add "  (none mapped - only unmapped/ephemeral ports detected)"
fi
add ""

# ---- Required Ports (mapped) ----
add "Required Ports (mapped):"
if [[ "${#seen_mapped[@]}" -gt 0 ]]; then
  printf "%s\n" "${!seen_mapped[@]}" | sort -t/ -k1,1n -k2,2 | while read -r key; do
    add "  ${key}  -> ${seen_mapped[$key]}"
  done
else
  add "  (none)"
fi
add ""

# ---- Unmapped ports ----
add "Other Listening Ports (unmapped):"
if [[ "${#seen_unmapped[@]}" -gt 0 ]]; then
  printf "%s\n" "${!seen_unmapped[@]}" | sort -t/ -k1,1n -k2,2 | while read -r key; do
    add "  $key"
  done
else
  add "  (none)"
fi
add ""

# ---- Evidence section ----
add "Evidence (Listening Port -> Process -> Service/Program):"
if [[ -n "${ROWS// }" ]]; then
  while read -r proto port pid proc; do
    p="$(norm_proto "$proto")"
    label="$(service_label "$port")"
    [[ -n "$label" ]] && label=" | Mapped:$label"
    [[ -z "${pid:-}" ]] && pid="?"
    [[ -z "${proc:-}" ]] && proc="?"

    add "  ${port}/${p}  PID:${pid}  Proc:${proc}${label}"
  done <<< "$ROWS"
else
  add "  (no ss/netstat output or insufficient permissions)"
fi
add ""

# ---- Containers ----
add "Containers:"
if command -v docker >/dev/null 2>&1; then
  add "  Docker detected:"
  docker ps -a --format '  {{.Names}} | {{.Image}} | {{.Status}} | {{.Ports}}' 2>/dev/null >> "$OUTFILE" || add "  (docker command failed)"
else
  add "  Docker not installed."
fi
add ""
add "Saved to: $(pwd)/${OUTFILE}"

echo "Saved: ${OUTFILE}"
