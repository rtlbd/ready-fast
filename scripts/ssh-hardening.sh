#!/usr/bin/env bash
# Description: Apply safer OpenSSH server settings through a drop-in file, with built-in rollback
# Requires-Root: yes
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
. "$SCRIPT_DIR/../lib/common.sh"

SSHD_CONFIG="/etc/ssh/sshd_config"
DROPIN_DIR="/etc/ssh/sshd_config.d"
DROPIN_FILE="$DROPIN_DIR/00-ready-fast.conf"
BACKUP_DIR="$RF_BACKUP_ROOT/ssh-hardening"

ROOT_LOGIN=""
DISABLE_PASSWORD=0
ROLLBACK=0

usage() {
  cat <<'USAGE'
Usage: ready-fast run ssh-hardening [options]

Writes /etc/ssh/sshd_config.d/00-ready-fast.conf with safer OpenSSH server
settings, checks the configuration with "sshd -t" and reloads the SSH service.
The main sshd_config file and the SSH port are never modified.

Always applied:
  PermitEmptyPasswords no, MaxAuthTries 4, LoginGraceTime 30,
  X11Forwarding no, ClientAliveInterval 300, ClientAliveCountMax 2

Options:
  --root-login <mode>       Set PermitRootLogin: yes, prohibit-password or no
  --disable-password-auth   Turn off password logins (SSH keys only)
  --rollback                Remove the drop-in file and reload the SSH service
  --dry-run                 Show what would be done without changing anything
  --yes                     Do not ask for confirmation
  --help                    Show this help

Root permission is required (also with --dry-run). Supported: Ubuntu 22.04, 24.04, 26.04 and
Debian 12, 13.
USAGE
}

while (($# > 0)); do
  case "$1" in
    --root-login)
      rf_need_value "$1" "$#"
      ROOT_LOGIN="$2"
      shift 2
      ;;
    --disable-password-auth)
      DISABLE_PASSWORD=1
      shift
      ;;
    --rollback)
      ROLLBACK=1
      shift
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

case "$ROOT_LOGIN" in
  "" | yes | prohibit-password | no) ;;
  *) rf_usage_error "Invalid --root-login value: $ROOT_LOGIN (expected yes, prohibit-password or no)" ;;
esac
if ((ROLLBACK)) && { [[ -n "$ROOT_LOGIN" ]] || ((DISABLE_PASSWORD)); }; then
  rf_usage_error "--rollback cannot be combined with --root-login or --disable-password-auth."
fi

rf_require_supported_os
rf_require_root

if ! rf_has_cmd sshd; then
  rf_die "The OpenSSH server (sshd) is not installed. Nothing was changed."
fi

# Reload the SSH service so that the new configuration is used.
reload_ssh() {
  if rf_systemd_running && systemctl is-active --quiet ssh; then
    rf_run systemctl reload ssh
    rf_ok "The SSH service was reloaded."
  else
    rf_warn "The ssh service is not running under systemd, so it was not reloaded. The settings apply the next time sshd starts."
  fi
}

if ((ROLLBACK)); then
  if [[ ! -f "$DROPIN_FILE" ]]; then
    rf_ok "$DROPIN_FILE does not exist. Nothing to roll back."
    exit 0
  fi
  rf_confirm "Remove $DROPIN_FILE and reload the SSH service?"
  if ((RF_DRY_RUN)); then
    rf_run rm -f -- "$DROPIN_FILE"
    rf_ok "Dry run finished. Nothing was changed."
    exit 0
  fi
  install -d -m 0700 "$BACKUP_DIR"
  cp -p -- "$DROPIN_FILE" "$BACKUP_DIR/00-ready-fast.conf.$(rf_timestamp)"
  rm -f -- "$DROPIN_FILE"
  if ! sshd -t; then
    rf_die "sshd reports a configuration error that is unrelated to ready-fast. The SSH service was not reloaded."
  fi
  reload_ssh
  rf_ok "Rollback complete. The ready-fast SSH settings were removed."
  exit 0
fi

if ! grep -Eiq '^[[:space:]]*Include[[:space:]]+/etc/ssh/sshd_config\.d/\*\.conf' "$SSHD_CONFIG"; then
  rf_die "$SSHD_CONFIG does not include $DROPIN_DIR/*.conf, so a drop-in file would have no effect. Nothing was changed."
fi

# True when the home directory has an authorized_keys file with at least one
# plain key line (lines that start with options such as command="..." are ignored).
has_ssh_key() {
  local file="$1/.ssh/authorized_keys"
  [[ -f "$file" ]] && grep -Eq '^[[:space:]]*(ssh-(rsa|ed25519)|ecdsa-sha2-|sk-(ssh-ed25519|ecdsa-sha2-))' "$file"
}

ROOT_HAS_KEY=0
NONROOT_LOGIN_USERS=0
NONROOT_KEY_USERS=0
while IFS=: read -r _name _pw uid _gid _gecos home shell; do
  case "$shell" in
    */nologin | */false | "") continue ;;
  esac
  if [[ "$uid" -eq 0 ]]; then
    if has_ssh_key "$home"; then
      ROOT_HAS_KEY=1
    fi
  elif [[ "$uid" -ge 1000 && "$uid" -lt 65534 ]]; then
    NONROOT_LOGIN_USERS=$((NONROOT_LOGIN_USERS + 1))
    if has_ssh_key "$home"; then
      NONROOT_KEY_USERS=$((NONROOT_KEY_USERS + 1))
    fi
  fi
done < <(getent passwd)

# Root login mode that will be in effect after this run.
EFFECTIVE_ROOT_LOGIN="$ROOT_LOGIN"
if [[ -z "$EFFECTIVE_ROOT_LOGIN" ]]; then
  EFFECTIVE_ROOT_LOGIN="$(sshd -T 2>/dev/null | awk '$1 == "permitrootlogin" { print $2 }' || true)"
  # OpenSSH prints the old name "without-password" for prohibit-password.
  if [[ "$EFFECTIVE_ROOT_LOGIN" == "without-password" ]]; then
    EFFECTIVE_ROOT_LOGIN="prohibit-password"
  fi
fi

# Safety checks: refuse settings that would leave nobody able to log in.
if [[ "$ROOT_LOGIN" == "no" ]] && ((NONROOT_LOGIN_USERS == 0)); then
  rf_die "Refusing --root-login no: there is no regular user (UID 1000 or higher) who could log in instead. Nothing was changed."
fi
if [[ "$ROOT_LOGIN" == "prohibit-password" ]] && ((ROOT_HAS_KEY == 0 && NONROOT_LOGIN_USERS == 0)); then
  rf_die "Refusing --root-login prohibit-password: root has no SSH key and there is no regular user to log in with. Nothing was changed."
fi
if ((DISABLE_PASSWORD)); then
  USABLE_KEY_USERS=$NONROOT_KEY_USERS
  if ((ROOT_HAS_KEY)) && [[ "$EFFECTIVE_ROOT_LOGIN" == "yes" || "$EFFECTIVE_ROOT_LOGIN" == "prohibit-password" ]]; then
    USABLE_KEY_USERS=$((USABLE_KEY_USERS + 1))
  fi
  if ((USABLE_KEY_USERS == 0)); then
    rf_die "Refusing --disable-password-auth: no account that is allowed to log in has an SSH key in ~/.ssh/authorized_keys. Add your public key first. Nothing was changed."
  fi
fi

CONTENT="# Managed by ready-fast (ssh-hardening). Do not edit by hand.
# Remove with: ready-fast run ssh-hardening --rollback
PermitEmptyPasswords no
MaxAuthTries 4
LoginGraceTime 30
X11Forwarding no
ClientAliveInterval 300
ClientAliveCountMax 2"
if [[ -n "$ROOT_LOGIN" ]]; then
  CONTENT+=$'\n'"PermitRootLogin $ROOT_LOGIN"
fi
if ((DISABLE_PASSWORD)); then
  CONTENT+=$'\n'"PasswordAuthentication no"
  CONTENT+=$'\n'"KbdInteractiveAuthentication no"
fi

rf_info "System: $RF_OS_PRETTY"
rf_info "This file will be written: $DROPIN_FILE"
printf '%s\n' "$CONTENT" | sed 's/^/    /'
if ((DISABLE_PASSWORD)) || [[ "$ROOT_LOGIN" == "no" || "$ROOT_LOGIN" == "prohibit-password" ]]; then
  rf_warn "These settings restrict how you can log in. Keep your current SSH session open until a new login has been tested."
fi
rf_confirm "Apply these SSH settings?"

if ((RF_DRY_RUN)); then
  rf_write_file "$DROPIN_FILE" 0600 "$CONTENT"
  rf_run sshd -t
  rf_ok "Dry run finished. Nothing was changed."
  exit 0
fi

PREVIOUS=""
if [[ -f "$DROPIN_FILE" ]]; then
  install -d -m 0700 "$BACKUP_DIR"
  PREVIOUS="$BACKUP_DIR/00-ready-fast.conf.$(rf_timestamp)"
  cp -p -- "$DROPIN_FILE" "$PREVIOUS"
  rf_info "The previous version was saved to $PREVIOUS"
fi

install -d -m 0755 "$DROPIN_DIR"
rf_write_file "$DROPIN_FILE" 0600 "$CONTENT"

if ! sshd -t; then
  if [[ -n "$PREVIOUS" ]]; then
    cp -p -- "$PREVIOUS" "$DROPIN_FILE"
  else
    rm -f -- "$DROPIN_FILE"
  fi
  rf_die "sshd rejected the new configuration, so the change was undone. The SSH service was not reloaded."
fi
rf_ok "sshd accepted the new configuration."

reload_ssh

rf_info "Settings now in effect:"
sshd -T 2>/dev/null | grep -Ei '^(permitrootlogin|passwordauthentication|kbdinteractiveauthentication|permitemptypasswords|maxauthtries|logingracetime|x11forwarding|clientaliveinterval|clientalivecountmax) ' | sed 's/^/    /' || true
rf_ok "Done. Keep this session open and test a new SSH login from another terminal."
