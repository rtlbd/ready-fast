#!/usr/bin/env bash
# Smoke tests for the ready-fast CLI and scripts.
# They are safe to run anywhere: nothing outside a temporary directory is changed.
# Usage: bash tests/smoke.sh
set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
RF="$ROOT/ready-fast"
export NO_COLOR=1

TMP="$(mktemp -d)"
trap 'rm -rf -- "$TMP"' EXIT

PASS=0
FAIL=0

pass() {
  PASS=$((PASS + 1))
  printf 'ok   - %s\n' "$1"
}

fail() {
  FAIL=$((FAIL + 1))
  printf 'FAIL - %s\n' "$1"
}

# expect_rc <description> <expected status, e.g. "0" or "0|1"> <command...>
expect_rc() {
  local desc="$1" expected="$2" rc=0
  shift 2
  "$@" >"$TMP/out.log" 2>&1 || rc=$?
  if [[ "|$expected|" == *"|$rc|"* ]]; then
    pass "$desc"
  else
    fail "$desc (exit status $rc, expected $expected)"
    sed 's/^/       /' "$TMP/out.log"
  fi
}

# expect_output <description> <text that must appear in the last command's output>
expect_output() {
  if grep -qF -- "$2" "$TMP/out.log"; then
    pass "$1"
  else
    fail "$1 (missing text: $2)"
    sed 's/^/       /' "$TMP/out.log"
  fi
}

echo "# CLI"
expect_rc "help exits 0" 0 "$RF" help
expect_rc "no arguments shows help" 0 "$RF"
expect_output "help lists the run command" "run <script> [options]"
expect_rc "version exits 0" 0 "$RF" version
expect_output "version matches the VERSION file" "ready-fast $(head -n 1 "$ROOT/VERSION")"
expect_rc "list exits 0" 0 "$RF" list
for script in "$ROOT"/scripts/*.sh; do
  name="$(basename -- "$script" .sh)"
  if grep -q -- "^$name " "$TMP/out.log"; then
    pass "list shows $name"
  else
    fail "list shows $name"
  fi
done
expect_rc "unknown command exits 2" 2 "$RF" no-such-command
expect_rc "unknown script exits 2" 2 "$RF" run no-such-script
expect_rc "invalid script name exits 2" 2 "$RF" run ../lib/common
expect_rc "run without a script exits 2" 2 "$RF" run
expect_rc "info without a script exits 2" 2 "$RF" info
expect_rc "doctor exits 0 or 1" "0|1" "$RF" doctor
expect_output "doctor prints the OS line" "OS:"

printf 'ID=fedora\nVERSION_ID=41\nVERSION_CODENAME=""\nPRETTY_NAME="Fedora Linux 41"\n' >"$TMP/os-release"
expect_rc "doctor fails on an unsupported OS" 1 env READY_FAST_OS_RELEASE="$TMP/os-release" "$RF" doctor
expect_output "doctor names the unsupported OS" "Fedora Linux 41 (NOT supported)"

echo "# Every script: --help, metadata, unknown option"
for script in "$ROOT"/scripts/*.sh; do
  name="$(basename -- "$script" .sh)"
  expect_rc "$name --help exits 0" 0 "$RF" run "$name" --help
  expect_output "$name --help shows its usage line" "Usage: ready-fast run $name"
  expect_rc "info $name exits 0" 0 "$RF" info "$name"
  expect_rc "$name rejects an unknown option" 2 "$RF" run "$name" --no-such-option
  if grep -q '^# Description: .' "$script" && grep -Eq '^# Requires-Root: (yes|no|depends)$' "$script"; then
    pass "$name has Description and Requires-Root headers"
  else
    fail "$name has Description and Requires-Root headers"
  fi
done

echo "# OS guard"
for name in docker-install firewall-setup ssh-hardening; do
  expect_rc "$name refuses an unsupported OS" 1 env READY_FAST_OS_RELEASE="$TMP/os-release" "$RF" run "$name" --dry-run
  expect_output "$name explains the refusal" "Unsupported operating system"
done

echo "# Option validation"
expect_rc "docker-install --user needs a value" 2 "$RF" run docker-install --user
expect_rc "firewall-setup rejects port 70000" 2 "$RF" run firewall-setup --allow 70000
expect_rc "firewall-setup rejects protocol icmp" 2 "$RF" run firewall-setup --allow 80/icmp
expect_rc "firewall-setup rejects SSH port 0" 2 "$RF" run firewall-setup --ssh-port 0
expect_rc "ssh-hardening rejects a bad --root-login" 2 "$RF" run ssh-hardening --root-login maybe
expect_rc "ssh-hardening rejects --rollback with other options" 2 "$RF" run ssh-hardening --rollback --disable-password-auth
expect_rc "system-monitor rejects --disk-warn 0" 2 "$RF" run system-monitor --disk-warn 0
expect_rc "system-monitor rejects --mem-warn 101" 2 "$RF" run system-monitor --mem-warn 101
expect_rc "backup-create needs --source" 2 "$RF" run backup-create
expect_rc "backup-create rejects a bad --name" 2 "$RF" run backup-create --source "$TMP" --name 'a/b'
expect_rc "backup-create rejects a bad --keep" 2 "$RF" run backup-create --source "$TMP" --keep many
expect_rc "backup-restore needs --file" 2 "$RF" run backup-restore --list
expect_rc "backup-restore needs --target or --list" 2 "$RF" run backup-restore --file "$TMP/os-release"
expect_rc "backup-restore rejects --list with --target" 2 "$RF" run backup-restore --file "$TMP/os-release" --list --target "$TMP/x"

echo "# Read-only scripts"
expect_rc "system-monitor runs" "0|1" "$RF" run system-monitor
expect_output "system-monitor prints the memory section" "== Memory =="
expect_rc "network-info runs" 0 "$RF" run network-info
expect_output "network-info prints the DNS section" "== DNS servers =="

echo "# Root guard and dry runs"
if [[ "$(id -u)" -eq 0 ]]; then
  expect_rc "firewall-setup --dry-run exits 0" 0 "$RF" run firewall-setup --dry-run --ssh-port 2222 --web --allow 51820/udp
  expect_output "dry run prints the SSH rule" "[DRY-RUN] ufw allow 2222/tcp"
  expect_output "dry run prints the web rule" "[DRY-RUN] ufw allow 443/tcp"
  expect_output "dry run prints the extra rule" "[DRY-RUN] ufw allow 51820/udp"
  expect_output "dry run changes nothing" "Dry run finished. Nothing was changed."
  expect_rc "docker-install --dry-run exits 0" 0 "$RF" run docker-install --dry-run
  expect_output "docker-install dry run changes nothing" "Nothing was changed."
else
  for name in docker-install firewall-setup; do
    expect_rc "$name refuses to run without root" 1 "$RF" run "$name" --dry-run
    expect_output "$name asks for sudo" "must be run as root"
  done
fi

echo "# Backup round trip"
SRC="$TMP/data"
DEST="$SRC/backups"
mkdir -p "$SRC/dir one" "$DEST"
echo "hello" >"$SRC/file.txt"
echo "with space" >"$SRC/dir one/second file.txt"
chmod 640 "$SRC/file.txt"

expect_rc "backup-create --dry-run exits 0" 0 "$RF" run backup-create --source "$SRC" --dest "$DEST" --name smoke --dry-run
if [[ -z "$(ls -A "$DEST")" ]]; then
  pass "backup-create --dry-run creates no files"
else
  fail "backup-create --dry-run creates no files"
fi

expect_rc "backup-create exits 0" 0 "$RF" run backup-create --source "$SRC" --dest "$DEST" --name smoke
ARCHIVE="$(find "$DEST" -name 'smoke-*.tar.gz' | sort | tail -n 1)"
if [[ -n "$ARCHIVE" && -f "$ARCHIVE.sha256" ]]; then
  pass "archive and checksum file exist"
else
  fail "archive and checksum file exist"
fi
if [[ "$(stat -c %a "$ARCHIVE")" == "600" ]]; then
  pass "archive is readable by its owner only"
else
  fail "archive is readable by its owner only"
fi

expect_rc "backup-restore --list exits 0" 0 "$RF" run backup-restore --file "$ARCHIVE" --list
expect_output "checksum is verified" "Checksum verified"
expect_output "archive contains file.txt" "${SRC#/}/file.txt"
if grep -qF -- "${DEST#/}" "$TMP/out.log"; then
  fail "destination directory is excluded from the archive"
else
  pass "destination directory is excluded from the archive"
fi

expect_rc "backup-restore without a terminal needs --yes" 1 "$RF" run backup-restore --file "$ARCHIVE" --target "$TMP/restore" </dev/null
expect_rc "backup-restore --dry-run exits 0" 0 "$RF" run backup-restore --file "$ARCHIVE" --target "$TMP/restore" --dry-run
if [[ ! -e "$TMP/restore" ]]; then
  pass "backup-restore --dry-run extracts nothing"
else
  fail "backup-restore --dry-run extracts nothing"
fi
expect_rc "backup-restore exits 0" 0 "$RF" run backup-restore --file "$ARCHIVE" --target "$TMP/restore" --yes
if diff -r --exclude backups "$SRC" "$TMP/restore$SRC" >/dev/null; then
  pass "restored files are identical to the originals"
else
  fail "restored files are identical to the originals"
fi
if [[ "$(stat -c %a "$TMP/restore$SRC/file.txt")" == "640" ]]; then
  pass "file permissions are preserved"
else
  fail "file permissions are preserved"
fi

# Retention: make three more archives with fake timestamps, then keep two.
for stamp in 20200101-000001 20200101-000002 20200101-000003; do
  cp "$ARCHIVE" "$DEST/smoke-$stamp.tar.gz"
  (cd "$DEST" && sha256sum "smoke-$stamp.tar.gz" >"smoke-$stamp.tar.gz.sha256")
done
touch "$DEST/smoke-extra-20200101-000000.tar.gz" "$DEST/smokeX-20200101-000000.tar.gz"
sleep 1 # archive names have one-second resolution
expect_rc "backup-create --keep 2 exits 0" 0 "$RF" run backup-create --source "$SRC/file.txt" --dest "$DEST" --name smoke --keep 2
remaining="$(find "$DEST" -name 'smoke-2*.tar.gz' | wc -l)"
if [[ "$remaining" -eq 2 ]]; then
  pass "retention keeps exactly two archives"
else
  fail "retention keeps exactly two archives (found $remaining)"
fi
if [[ ! -e "$DEST/smoke-20200101-000001.tar.gz" && ! -e "$DEST/smoke-20200101-000001.tar.gz.sha256" ]]; then
  pass "retention removes the oldest archive and its checksum"
else
  fail "retention removes the oldest archive and its checksum"
fi
if [[ -e "$DEST/smoke-extra-20200101-000000.tar.gz" && -e "$DEST/smokeX-20200101-000000.tar.gz" ]]; then
  pass "retention leaves archives with other names alone"
else
  fail "retention leaves archives with other names alone"
fi

NEWEST="$(find "$DEST" -name 'smoke-2*.tar.gz' | sort | tail -n 1)"
echo "damage" >>"$NEWEST"
expect_rc "a damaged archive is rejected" 1 "$RF" run backup-restore --file "$NEWEST" --target "$TMP/restore2" --yes
expect_output "the checksum mismatch is reported" "Checksum mismatch"
if [[ ! -e "$TMP/restore2" ]]; then
  pass "nothing is extracted from a damaged archive"
else
  fail "nothing is extracted from a damaged archive"
fi

expect_rc "backup-create fails for a missing source" 1 "$RF" run backup-create --source "$TMP/does-not-exist" --dest "$DEST"
expect_rc "backup-create refuses to back up /" 1 "$RF" run backup-create --source / --dest "$DEST"

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
if ((FAIL > 0)); then
  exit 1
fi
