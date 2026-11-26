#!/usr/bin/env bash
# Description: Configure the UFW firewall: deny incoming traffic, keep SSH open, allow chosen ports
# Requires-Root: yes
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
. "$SCRIPT_DIR/../lib/common.sh"

SSH_PORT_OVERRIDE=""
ALLOW_WEB=0
EXTRA_RULES=()

usage() {
  cat <<'USAGE'
Usage: ready-fast run firewall-setup [options]

Installs UFW, sets the default policy to "deny incoming / allow outgoing",
allows the SSH port and any ports you choose, then enables the firewall.
Existing UFW rules are kept.

Options:
  --ssh-port <port>        SSH port to keep open (default: detected from sshd, else 22)
  --web                    Also allow HTTP (80/tcp) and HTTPS (443/tcp)
  --allow <port[/proto]>   Also allow this port; proto is tcp or udp (repeatable)
  --dry-run                Show what would be done without changing anything
  --yes                    Do not ask for confirmation
  --help                   Show this help

Root permission is required (also with --dry-run). Supported: Ubuntu 22.04, 24.04, 26.04 and
Debian 12, 13.
USAGE
}

valid_port() {
  [[ "$1" =~ ^[0-9]{1,5}$ ]] && ((10#$1 >= 1 && 10#$1 <= 65535))
}

while (($# > 0)); do
  case "$1" in
    --ssh-port)
      rf_need_value "$1" "$#"
      SSH_PORT_OVERRIDE="$2"
      shift 2
      ;;
    --web)
      ALLOW_WEB=1
      shift
      ;;
    --allow)
      rf_need_value "$1" "$#"
      EXTRA_RULES+=("$2")
      shift 2
      ;;
    --dry-run)
      RF_DRY_RUN=1
      shift
      ;;
    --yes)
      RF_ASSUME_YES=1
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

if [[ -n "$SSH_PORT_OVERRIDE" ]] && ! valid_port "$SSH_PORT_OVERRIDE"; then
  rf_usage_error "Invalid SSH port: $SSH_PORT_OVERRIDE (expected a number from 1 to 65535)"
fi
if ((${#EXTRA_RULES[@]} > 0)); then
  for rule in "${EXTRA_RULES[@]}"; do
    if [[ ! "$rule" =~ ^[0-9]{1,5}(/(tcp|udp))?$ ]] || ! valid_port "${rule%%/*}"; then
      rf_usage_error "Invalid --allow value: $rule (expected <port> or <port>/tcp or <port>/udp)"
    fi
  done
fi

rf_require_supported_os
rf_require_root

if rf_systemd_running && systemctl is-active --quiet firewalld 2>/dev/null; then
  rf_die "firewalld is active on this system. Running two firewall managers together is unsafe; nothing was changed."
fi

# Collect every port sshd is using, so the current SSH access is not cut off.
detect_ssh_ports() {
  local port
  if [[ -n "${SSH_CONNECTION:-}" ]]; then
    # SSH_CONNECTION = "<client ip> <client port> <server ip> <server port>"
    port="${SSH_CONNECTION##* }"
    if valid_port "$port"; then
      printf '%s\n' "$port"
    fi
  fi
  if rf_has_cmd sshd; then
    sshd -T 2>/dev/null | awk '$1 == "port" { print $2 }' || true
  fi
}

mapfile -t DETECTED_PORTS < <(detect_ssh_ports | sort -un)

SSH_PORTS=()
if [[ -n "$SSH_PORT_OVERRIDE" ]]; then
  SSH_PORTS=("$SSH_PORT_OVERRIDE")
  if ((${#DETECTED_PORTS[@]} > 0)); then
    for port in "${DETECTED_PORTS[@]}"; do
      if [[ "$port" != "$SSH_PORT_OVERRIDE" ]]; then
        rf_warn "sshd appears to use port $port, but only port $SSH_PORT_OVERRIDE will be allowed (--ssh-port)."
      fi
    done
  fi
elif ((${#DETECTED_PORTS[@]} > 0)); then
  SSH_PORTS=("${DETECTED_PORTS[@]}")
else
  rf_warn "Could not detect the SSH port; assuming 22."
  SSH_PORTS=(22)
fi

RULES=()
for port in "${SSH_PORTS[@]}"; do
  RULES+=("$port/tcp")
done
if ((ALLOW_WEB)); then
  RULES+=("80/tcp" "443/tcp")
fi
if ((${#EXTRA_RULES[@]} > 0)); then
  RULES+=("${EXTRA_RULES[@]}")
fi

rf_info "System: $RF_OS_PRETTY"
rf_info "The following will be done:"
rf_info "  1. Install the package ufw (if missing)"
rf_info "  2. Default policy: deny incoming, allow outgoing"
rf_info "  3. Allow incoming: ${RULES[*]}"
rf_info "  4. Enable the firewall now and at every boot"
rf_warn "If the SSH port above is wrong, you can lock yourself out of this server."
rf_confirm "Apply these firewall settings?"

rf_info "Step 1/4: installing ufw"
if rf_has_cmd ufw; then
  rf_info "ufw is already installed."
else
  rf_apt_update
  rf_apt_install ufw
fi

rf_info "Step 2/4: setting the default policy"
rf_run ufw default deny incoming
rf_run ufw default allow outgoing

rf_info "Step 3/4: adding allow rules"
for rule in "${RULES[@]}"; do
  rf_run ufw allow "$rule"
done

rf_info "Step 4/4: enabling the firewall"
rf_run ufw --force enable

if ((RF_DRY_RUN)); then
  rf_ok "Dry run finished. Nothing was changed."
  exit 0
fi

ufw status verbose
rf_ok "The firewall is active. Keep this session open and confirm that a new SSH login still works."
