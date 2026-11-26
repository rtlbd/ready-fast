#!/usr/bin/env bash
# ready-fast shared helper library.
# This file is sourced by the ready-fast CLI and by every script in scripts/.
# It must not be executed directly.
#
# Variables defined here are used by the files that source this library.
# shellcheck disable=SC2034

# Operating systems that ready-fast supports, as "<ID>:<VERSION_ID>" pairs
# taken from /etc/os-release.
RF_SUPPORTED_OS=("ubuntu:22.04" "ubuntu:24.04" "ubuntu:26.04" "debian:12" "debian:13")

# CPU architectures (as printed by `dpkg --print-architecture`) that are supported.
RF_SUPPORTED_ARCH=("amd64" "arm64")

# Directory where ready-fast keeps copies of files it replaces.
RF_BACKUP_ROOT="/var/backups/ready-fast"

RF_DRY_RUN=0
RF_ASSUME_YES=0

RF_OS_ID=""
RF_OS_VERSION_ID=""
RF_OS_CODENAME=""
RF_OS_PRETTY=""

if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
  RF_C_RED=$'\033[31m'
  RF_C_GREEN=$'\033[32m'
  RF_C_YELLOW=$'\033[33m'
  RF_C_BLUE=$'\033[34m'
  RF_C_RESET=$'\033[0m'
else
  RF_C_RED=""
  RF_C_GREEN=""
  RF_C_YELLOW=""
  RF_C_BLUE=""
  RF_C_RESET=""
fi

rf_info() { printf '%s[INFO]%s %s\n' "$RF_C_BLUE" "$RF_C_RESET" "$*"; }
rf_ok() { printf '%s[OK]%s %s\n' "$RF_C_GREEN" "$RF_C_RESET" "$*"; }
rf_warn() { printf '%s[WARN]%s %s\n' "$RF_C_YELLOW" "$RF_C_RESET" "$*" >&2; }
rf_error() { printf '%s[ERROR]%s %s\n' "$RF_C_RED" "$RF_C_RESET" "$*" >&2; }

# Print an error and exit with status 1 (runtime failure).
rf_die() {
  rf_error "$*"
  exit 1
}

# Print an error about wrong command-line usage and exit with status 2.
rf_usage_error() {
  rf_error "$*"
  rf_error "Run the same command with --help to see the available options."
  exit 2
}

# rf_need_value <option> <number of remaining arguments>
# Fails with a usage error when an option that needs a value has none.
rf_need_value() {
  if (($2 < 2)); then
    rf_usage_error "Option $1 requires a value."
  fi
}

rf_has_cmd() { command -v "$1" >/dev/null 2>&1; }

rf_is_root() { [[ "$(id -u)" -eq 0 ]]; }

rf_require_root() {
  if ! rf_is_root; then
    rf_die "This script must be run as root. Re-run it with sudo."
  fi
}

rf_systemd_running() { [[ -d /run/systemd/system ]]; }

# Read ID, VERSION_ID, VERSION_CODENAME and PRETTY_NAME from os-release.
# READY_FAST_OS_RELEASE can point to another file; this is meant for tests only.
rf_detect_os() {
  local file="${READY_FAST_OS_RELEASE:-/etc/os-release}"
  if [[ ! -r "$file" ]]; then
    rf_die "Cannot read $file, so the operating system cannot be detected."
  fi
  RF_OS_ID="$(
    # shellcheck disable=SC1090
    . "$file"
    printf '%s' "${ID:-}"
  )"
  RF_OS_VERSION_ID="$(
    # shellcheck disable=SC1090
    . "$file"
    printf '%s' "${VERSION_ID:-}"
  )"
  RF_OS_CODENAME="$(
    # shellcheck disable=SC1090
    . "$file"
    printf '%s' "${VERSION_CODENAME:-}"
  )"
  RF_OS_PRETTY="$(
    # shellcheck disable=SC1090
    . "$file"
    printf '%s' "${PRETTY_NAME:-unknown}"
  )"
}

# Return 0 when the detected OS is in RF_SUPPORTED_OS. Call rf_detect_os first.
rf_os_supported() {
  local entry
  for entry in "${RF_SUPPORTED_OS[@]}"; do
    if [[ "$entry" == "${RF_OS_ID}:${RF_OS_VERSION_ID}" ]]; then
      return 0
    fi
  done
  return 1
}

rf_require_supported_os() {
  rf_detect_os
  if ! rf_os_supported; then
    rf_die "Unsupported operating system: ${RF_OS_PRETTY}. Supported: Ubuntu 22.04, 24.04, 26.04 and Debian 12, 13."
  fi
  if [[ -z "$RF_OS_CODENAME" ]]; then
    rf_die "VERSION_CODENAME is missing from the os-release file, so the release codename is unknown."
  fi
}

# Print the Debian architecture name (amd64, arm64, ...).
rf_arch() {
  if rf_has_cmd dpkg; then
    dpkg --print-architecture
  else
    case "$(uname -m)" in
      x86_64) echo "amd64" ;;
      aarch64) echo "arm64" ;;
      *) uname -m ;;
    esac
  fi
}

rf_arch_supported() {
  local arch entry
  arch="$(rf_arch)"
  for entry in "${RF_SUPPORTED_ARCH[@]}"; do
    if [[ "$entry" == "$arch" ]]; then
      return 0
    fi
  done
  return 1
}

rf_require_supported_arch() {
  if ! rf_arch_supported; then
    rf_die "Unsupported CPU architecture: $(rf_arch). Supported: amd64, arm64."
  fi
}

# Run a command, or only print it when --dry-run is active.
rf_run() {
  if ((RF_DRY_RUN)); then
    printf '[DRY-RUN] %s\n' "$(printf '%q ' "$@" | sed 's/ $//')"
    return 0
  fi
  "$@"
}

# rf_write_file <path> <mode> <content>
# Write a file with the given permissions, or only show it in --dry-run mode.
rf_write_file() {
  local path="$1" mode="$2" content="$3"
  if ((RF_DRY_RUN)); then
    printf '[DRY-RUN] write %s (mode %s) with this content:\n' "$path" "$mode"
    printf '%s\n' "$content" | sed 's/^/[DRY-RUN]   /'
    return 0
  fi
  printf '%s\n' "$content" >"$path"
  chmod "$mode" "$path"
}

# Ask the user to confirm. --yes and --dry-run skip the question.
# Without a terminal the script stops instead of guessing.
rf_confirm() {
  local prompt="$1" answer=""
  if ((RF_ASSUME_YES || RF_DRY_RUN)); then
    return 0
  fi
  if [[ ! -t 0 ]]; then
    rf_die "Confirmation is required but no terminal is attached. Re-run with --yes to continue without a prompt."
  fi
  read -r -p "$prompt [y/N]: " answer
  if [[ ! "$answer" =~ ^[Yy]([Ee][Ss])?$ ]]; then
    rf_die "Cancelled. No changes were made."
  fi
}

rf_apt_update() {
  rf_run env DEBIAN_FRONTEND=noninteractive apt-get update -o DPkg::Lock::Timeout=120
}

rf_apt_install() {
  rf_run env DEBIAN_FRONTEND=noninteractive apt-get install -y -o DPkg::Lock::Timeout=120 "$@"
}

# Return 0 when a Debian package is fully installed.
rf_pkg_installed() {
  local status
  status="$(dpkg-query -W -f='${db:Status-Abbrev}' "$1" 2>/dev/null || true)"
  [[ "$status" == ii* ]]
}

rf_timestamp() { date +%Y%m%d-%H%M%S; }
