#!/usr/bin/env bash
# Description: Show network interfaces, routes, DNS servers and listening ports (read-only)
# Requires-Root: no
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
. "$SCRIPT_DIR/../lib/common.sh"

SHOW_PUBLIC_IP=0
RUN_CHECK=0
PUBLIC_IP_URL="https://api.ipify.org"
CHECK_HOST="example.com"

usage() {
  cat <<'USAGE'
Usage: ready-fast run network-info [options]

Prints a read-only report of the network configuration: hostname, IP
addresses, default routes, DNS servers and listening ports.
Nothing on the system is changed.

Options:
  --public-ip   Also show the public IP address (sends one request to https://api.ipify.org)
  --check       Also test DNS resolution and outbound HTTPS using example.com
  --help        Show this help

Root permission is not required. Without root, the listening-ports table
does not show process names.
USAGE
}

while (($# > 0)); do
  case "$1" in
    --public-ip)
      SHOW_PUBLIC_IP=1
      shift
      ;;
    --check)
      RUN_CHECK=1
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      rf_usage_error "Unknown option: $1"
      ;;
  esac
done

FAILED=0

section() { printf '\n== %s ==\n' "$1"; }

section "Hostname"
hostname

section "IP addresses"
if rf_has_cmd ip; then
  ip -brief address show
else
  echo "(the 'ip' command is missing; install the iproute2 package)"
fi

section "Default routes"
if rf_has_cmd ip; then
  routes="$(
    ip route show default 2>/dev/null || true
    ip -6 route show default 2>/dev/null || true
  )"
  if [[ -n "$routes" ]]; then
    printf '%s\n' "$routes"
  else
    echo "(no default route)"
  fi
else
  echo "(the 'ip' command is missing; install the iproute2 package)"
fi

section "DNS servers"
if [[ -r /etc/resolv.conf ]]; then
  nameservers="$(awk '$1 == "nameserver" { print $2 }' /etc/resolv.conf)"
  if [[ -n "$nameservers" ]]; then
    printf '%s\n' "$nameservers"
  else
    echo "(no nameserver entries in /etc/resolv.conf)"
  fi
else
  echo "(/etc/resolv.conf is not readable)"
fi

section "Listening ports"
if rf_has_cmd ss; then
  if rf_is_root; then
    ss -tulnp
  else
    ss -tuln
  fi
else
  echo "(the 'ss' command is missing; install the iproute2 package)"
fi

if ((SHOW_PUBLIC_IP)); then
  section "Public IP address"
  if ! rf_has_cmd curl; then
    echo "SKIPPED (curl is not installed)"
  elif public_ip="$(curl -fsS --max-time 8 "$PUBLIC_IP_URL" 2>/dev/null)" && [[ -n "$public_ip" ]]; then
    printf '%s\n' "$public_ip"
  else
    echo "FAILED (could not reach $PUBLIC_IP_URL)"
    FAILED=1
  fi
fi

if ((RUN_CHECK)); then
  section "Connectivity check"
  if getent hosts "$CHECK_HOST" >/dev/null 2>&1; then
    echo "DNS resolution ($CHECK_HOST): OK"
  else
    echo "DNS resolution ($CHECK_HOST): FAILED"
    FAILED=1
  fi
  if ! rf_has_cmd curl; then
    echo "Outbound HTTPS (https://$CHECK_HOST): SKIPPED (curl is not installed)"
  elif curl -fsS --max-time 8 -o /dev/null "https://$CHECK_HOST" 2>/dev/null; then
    echo "Outbound HTTPS (https://$CHECK_HOST): OK"
  else
    echo "Outbound HTTPS (https://$CHECK_HOST): FAILED"
    FAILED=1
  fi
fi

printf '\n'
if ((FAILED)); then
  rf_error "At least one network check failed."
  exit 1
fi
rf_ok "Network report complete."
