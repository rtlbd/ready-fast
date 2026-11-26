#!/usr/bin/env bash
# System tests for ready-fast. THESE TESTS CHANGE THE MACHINE THEY RUN ON:
# they install ready-fast, Docker Engine and the OpenSSH server, and on
# machines with systemd they enable and then disable the UFW firewall.
# Run them only in a disposable container or virtual machine, as root:
#   READY_FAST_TEST_SYSTEM=1 bash tests/system.sh
set -Eeuo pipefail

if [[ "${READY_FAST_TEST_SYSTEM:-}" != "1" ]]; then
  echo "Refusing to run: set READY_FAST_TEST_SYSTEM=1 on a disposable machine." >&2
  exit 2
fi
if [[ "$(id -u)" -ne 0 ]]; then
  echo "tests/system.sh must be run as root." >&2
  exit 2
fi

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
export NO_COLOR=1
DROPIN="/etc/ssh/sshd_config.d/00-ready-fast.conf"

step() { printf '\n### %s\n' "$1"; }

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

step "install.sh"
"$ROOT/install.sh"
[[ -L /usr/local/bin/ready-fast ]] || fail "symlink /usr/local/bin/ready-fast was not created"
ready-fast version
ready-fast list
ready-fast doctor

if [[ "${READY_FAST_TEST_SKIP_DOCKER:-}" == "1" ]]; then
  step "docker-install (skipped: READY_FAST_TEST_SKIP_DOCKER=1)"
else
  step "docker-install --dry-run changes nothing"
  ready-fast run docker-install --dry-run
  [[ ! -e /etc/apt/sources.list.d/docker.list ]] || fail "dry run created docker.list"

  step "docker-install"
  ready-fast run docker-install --yes
  docker --version
  docker compose version
  [[ -s /etc/apt/keyrings/docker.asc ]] || fail "signing key is missing"
  grep -q "download.docker.com/linux" /etc/apt/sources.list.d/docker.list || fail "docker.list is wrong"

  step "docker-install is idempotent"
  ready-fast run docker-install --yes | tee /tmp/ready-fast-docker-second-run.log
  grep -q "already installed" /tmp/ready-fast-docker-second-run.log || fail "second run did not detect Docker"

  step "docker-install --user"
  id -u rftest >/dev/null 2>&1 || useradd --create-home rftest
  ready-fast run docker-install --user rftest --yes
  groups_of_rftest="$(id -nG rftest)"
  [[ " $groups_of_rftest " == *" docker "* ]] || fail "user rftest was not added to the docker group"
fi

step "ssh-hardening"
apt-get update >/dev/null
DEBIAN_FRONTEND=noninteractive apt-get install -y openssh-server >/dev/null
mkdir -p /run/sshd
if [[ -d /run/systemd/system ]]; then
  systemctl start ssh
fi
ready-fast run ssh-hardening --dry-run
[[ ! -e "$DROPIN" ]] || fail "dry run created the drop-in file"
ready-fast run ssh-hardening --yes
[[ -f "$DROPIN" ]] || fail "drop-in file was not created"
[[ "$(stat -c %a "$DROPIN")" == "600" ]] || fail "drop-in file has wrong permissions"
effective="$(sshd -T)"
grep -qx "maxauthtries 4" <<<"$effective" || fail "MaxAuthTries is not in effect"
grep -qx "x11forwarding no" <<<"$effective" || fail "X11Forwarding is not in effect"
grep -qx "logingracetime 30" <<<"$effective" || fail "LoginGraceTime is not in effect"
if [[ -d /run/systemd/system ]]; then
  systemctl is-active --quiet ssh || fail "the ssh service is not running after the reload"
fi

step "ssh-hardening refuses to lock everyone out"
if grep -qsE '^[[:space:]]*(ssh-|ecdsa-|sk-)' /root/.ssh/authorized_keys /home/*/.ssh/authorized_keys; then
  echo "skipped: an account on this machine already has an SSH key"
else
  rc=0
  ready-fast run ssh-hardening --disable-password-auth --yes || rc=$?
  [[ "$rc" -eq 1 ]] || fail "--disable-password-auth was accepted although nobody has an SSH key"
  [[ -f "$DROPIN" ]] || fail "the refused run removed the existing drop-in file"
  ! grep -q "PasswordAuthentication" "$DROPIN" || fail "password authentication was changed"
fi

step "ssh-hardening with key-only logins"
id -u rfkey >/dev/null 2>&1 || useradd --create-home --shell /bin/bash rfkey
install -d -m 0700 -o rfkey -g rfkey /home/rfkey/.ssh
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIReadyFastTestKeyNotARealKey0000000000000000 test" >/home/rfkey/.ssh/authorized_keys
ready-fast run ssh-hardening --disable-password-auth --root-login no --yes
effective="$(sshd -T)"
grep -qx "passwordauthentication no" <<<"$effective" || fail "PasswordAuthentication no is not in effect"
grep -qx "permitrootlogin no" <<<"$effective" || fail "PermitRootLogin no is not in effect"
ls /var/backups/ready-fast/ssh-hardening/00-ready-fast.conf.* >/dev/null || fail "previous drop-in was not backed up"

step "ssh-hardening --rollback"
ready-fast run ssh-hardening --rollback --yes
[[ ! -e "$DROPIN" ]] || fail "rollback did not remove the drop-in file"
sshd -t || fail "sshd configuration is invalid after rollback"

if [[ -d /run/systemd/system ]]; then
  step "firewall-setup"
  ready-fast run firewall-setup --yes --web --allow 51820/udp
  ufw status verbose >/tmp/ready-fast-ufw-status.log
  cat /tmp/ready-fast-ufw-status.log
  grep -q "^Status: active" /tmp/ready-fast-ufw-status.log || fail "ufw is not active"
  grep -q "deny (incoming), allow (outgoing)" /tmp/ready-fast-ufw-status.log || fail "default policy is wrong"
  for rule in 80/tcp 443/tcp 51820/udp; do
    grep -Eq "^$rule +ALLOW IN" /tmp/ready-fast-ufw-status.log || fail "rule $rule is missing"
  done
  grep -Eq "^[0-9]+/tcp +ALLOW IN" /tmp/ready-fast-ufw-status.log || fail "no SSH rule was added"

  step "firewall rollback (ufw disable)"
  ufw disable
  ufw_state="$(ufw status)"
  grep -q "^Status: inactive" <<<"$ufw_state" || fail "ufw is still active after ufw disable"
else
  step "firewall-setup --dry-run (no systemd here, so the firewall is not enabled for real)"
  ready-fast run firewall-setup --dry-run --web
fi

step "install.sh --uninstall"
"$ROOT/install.sh" --uninstall
[[ ! -e /usr/local/bin/ready-fast && ! -e /opt/ready-fast ]] || fail "uninstall left files behind"

printf '\nAll system tests passed.\n'
