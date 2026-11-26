#!/usr/bin/env bash
# install.sh - install or remove the ready-fast toolkit on this machine.
#
#   sudo ./install.sh              copy the toolkit to /opt/ready-fast and
#                                  create the /usr/local/bin/ready-fast command
#   sudo ./install.sh --uninstall  remove both again
set -Eeuo pipefail

SRC_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="/opt/ready-fast"
BIN_LINK="/usr/local/bin/ready-fast"

usage() {
  cat <<'USAGE'
Usage: sudo ./install.sh [--uninstall] [--help]

Without options, installs ready-fast:
  - copies the toolkit to /opt/ready-fast
  - creates the symlink /usr/local/bin/ready-fast

Options:
  --uninstall   Remove /opt/ready-fast and /usr/local/bin/ready-fast
  --help        Show this help

Nothing else on the system is changed. Backups and files created by
individual scripts are never touched by --uninstall.
USAGE
}

die() {
  printf '[ERROR] %s\n' "$*" >&2
  exit 1
}

require_root() {
  if [[ "$(id -u)" -ne 0 ]]; then
    die "install.sh must be run as root. Re-run it with sudo."
  fi
}

do_install() {
  local item
  for item in ready-fast VERSION lib/common.sh scripts; do
    if [[ ! -e "$SRC_DIR/$item" ]]; then
      die "$SRC_DIR/$item is missing. Run install.sh from a complete copy of the repository."
    fi
  done
  require_root

  if [[ -e "$BIN_LINK" && ! -L "$BIN_LINK" ]]; then
    die "$BIN_LINK exists and is not a symlink. Move it away and run install.sh again."
  fi

  rm -rf -- "$INSTALL_DIR"
  install -d -m 0755 "$INSTALL_DIR" "$INSTALL_DIR/lib" "$INSTALL_DIR/scripts"
  install -m 0755 "$SRC_DIR/ready-fast" "$INSTALL_DIR/ready-fast"
  install -m 0644 "$SRC_DIR/VERSION" "$INSTALL_DIR/VERSION"
  install -m 0644 "$SRC_DIR/lib/common.sh" "$INSTALL_DIR/lib/common.sh"
  install -m 0755 "$SRC_DIR"/scripts/*.sh "$INSTALL_DIR/scripts/"
  install -d -m 0755 "$(dirname -- "$BIN_LINK")"
  ln -sfn "$INSTALL_DIR/ready-fast" "$BIN_LINK"

  printf '[OK] Installed %s to %s\n' "$("$INSTALL_DIR/ready-fast" version)" "$INSTALL_DIR"
  printf '[OK] Command available: %s\n' "$BIN_LINK"
  printf '[INFO] Next step: ready-fast doctor\n'
}

do_uninstall() {
  require_root
  if [[ -L "$BIN_LINK" ]]; then
    rm -f -- "$BIN_LINK"
  elif [[ -e "$BIN_LINK" ]]; then
    die "$BIN_LINK is not a symlink created by ready-fast. It was not removed."
  fi
  rm -rf -- "$INSTALL_DIR"
  printf '[OK] Removed %s and %s\n' "$INSTALL_DIR" "$BIN_LINK"
}

case "${1:-}" in
  "")
    do_install
    ;;
  --uninstall)
    do_uninstall
    ;;
  -h | --help)
    usage
    ;;
  *)
    printf '[ERROR] Unknown option: %s\n' "$1" >&2
    usage >&2
    exit 2
    ;;
esac
