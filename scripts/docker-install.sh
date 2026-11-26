#!/usr/bin/env bash
# Description: Install Docker Engine and the Compose plugin from Docker's official apt repository
# Requires-Root: yes
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
. "$SCRIPT_DIR/../lib/common.sh"

DOCKER_PACKAGES=(docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin)
CONFLICTING_PACKAGES=(docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc)
DOCKER_KEY_FINGERPRINT="9DC858229FC7DD38854AE2D88D81803C0EBFCD88"
KEYRING_DIR="/etc/apt/keyrings"
KEY_FILE="$KEYRING_DIR/docker.asc"
LIST_FILE="/etc/apt/sources.list.d/docker.list"

TARGET_USER=""

usage() {
  cat <<'USAGE'
Usage: ready-fast run docker-install [options]

Installs Docker Engine, the Docker CLI, containerd, Buildx and the Compose
plugin from Docker's official apt repository, then enables the docker service.

Options:
  --user <name>   Also add this existing user to the "docker" group
  --dry-run       Show what would be done without changing anything
  --yes           Do not ask for confirmation
  --help          Show this help

Root permission is required (also with --dry-run). Supported: Ubuntu 22.04, 24.04, 26.04 and
Debian 12, 13 on amd64 or arm64.
USAGE
}

while (($# > 0)); do
  case "$1" in
    --user)
      rf_need_value "$1" "$#"
      TARGET_USER="$2"
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

rf_require_supported_os
rf_require_supported_arch
rf_require_root

if [[ -n "$TARGET_USER" ]] && ! id -u "$TARGET_USER" >/dev/null 2>&1; then
  rf_die "User '$TARGET_USER' does not exist. Create the user first or remove --user."
fi

REPO_URL="https://download.docker.com/linux/$RF_OS_ID"
ARCH="$(rf_arch)"

install_docker() {
  local pkg found=()

  for pkg in "${CONFLICTING_PACKAGES[@]}"; do
    if rf_pkg_installed "$pkg"; then
      found+=("$pkg")
    fi
  done
  if ((${#found[@]} > 0)); then
    rf_error "Conflicting packages are installed: ${found[*]}"
    rf_error "Remove them first, for example: sudo apt-get remove ${found[*]}"
    rf_die "Nothing was changed."
  fi

  rf_info "System: $RF_OS_PRETTY ($ARCH)"
  rf_info "The following will be done:"
  rf_info "  1. Install the packages ca-certificates and curl"
  rf_info "  2. Save Docker's signing key to $KEY_FILE"
  rf_info "  3. Add Docker's apt repository in $LIST_FILE"
  rf_info "  4. Install: ${DOCKER_PACKAGES[*]}"
  rf_info "  5. Enable and start the docker service"
  rf_confirm "Install Docker Engine now?"

  rf_info "Step 1/5: installing prerequisites"
  rf_apt_update
  rf_apt_install ca-certificates curl

  rf_info "Step 2/5: downloading Docker's signing key"
  if ((!RF_DRY_RUN)); then
    if ! curl -fsSI --max-time 20 "$REPO_URL/dists/$RF_OS_CODENAME/Release" >/dev/null; then
      rf_die "Docker's repository has no packages for '$RF_OS_CODENAME', or download.docker.com is unreachable. Nothing was added to apt."
    fi
  fi
  rf_run install -m 0755 -d "$KEYRING_DIR"
  rf_run curl -fsSL "$REPO_URL/gpg" -o "$KEY_FILE"
  rf_run chmod a+r "$KEY_FILE"
  if ((!RF_DRY_RUN)); then
    verify_key
  fi

  rf_info "Step 3/5: adding Docker's apt repository"
  rf_write_file "$LIST_FILE" 0644 \
    "deb [arch=$ARCH signed-by=$KEY_FILE] $REPO_URL $RF_OS_CODENAME stable"

  rf_info "Step 4/5: installing Docker packages"
  rf_apt_update
  rf_apt_install "${DOCKER_PACKAGES[@]}"

  rf_info "Step 5/5: enabling the docker service"
  if rf_systemd_running; then
    rf_run systemctl enable --now docker
  else
    rf_warn "systemd is not running here, so the docker service was not started."
  fi
}

# Compare the downloaded key with Docker's published fingerprint when gpg exists.
verify_key() {
  local fingerprint
  if ! rf_has_cmd gpg; then
    rf_warn "gpg is not installed, so the key fingerprint was not checked (the key was downloaded over HTTPS)."
    return 0
  fi
  fingerprint="$(gpg --show-keys --with-colons "$KEY_FILE" 2>/dev/null | awk -F: '$1 == "fpr" && !seen++ { print $10 }')"
  if [[ "$fingerprint" != "$DOCKER_KEY_FINGERPRINT" ]]; then
    rm -f -- "$KEY_FILE"
    rf_die "The downloaded key has an unexpected fingerprint (${fingerprint:-none}). It was deleted and nothing was installed."
  fi
  rf_ok "Signing key fingerprint verified."
}

if rf_pkg_installed docker-ce; then
  rf_ok "Docker Engine is already installed: $(docker --version 2>/dev/null || echo 'version unknown')"
  rf_info "Skipping installation."
else
  install_docker
fi

if [[ -n "$TARGET_USER" ]]; then
  rf_info "Adding user '$TARGET_USER' to the docker group"
  rf_run usermod -aG docker "$TARGET_USER"
  rf_warn "Members of the docker group have root-equivalent access to this machine."
  rf_info "'$TARGET_USER' must log out and log in again before the new group is active."
fi

if ((RF_DRY_RUN)); then
  rf_ok "Dry run finished. Nothing was changed."
  exit 0
fi

rf_info "Verifying the installation"
docker --version
docker compose version
if rf_systemd_running; then
  if systemctl is-active --quiet docker; then
    rf_ok "The docker service is running."
  else
    rf_die "Docker is installed but the docker service is not running. Check: journalctl -u docker --no-pager -n 50"
  fi
fi
rf_ok "Docker Engine is ready. Test it with: sudo docker run --rm hello-world"
