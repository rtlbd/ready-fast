#!/usr/bin/env bash
# Self-test for tools/validate-docs.py.
# It checks that the validator accepts the real documentation and that it
# FAILS when the two languages drift apart. Each case edits a temporary copy
# of the repository; the real files are never touched.
# Usage: bash tests/docs-validator.sh
set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf -- "$TMP"' EXIT

PASS=0
FAIL=0

# Copy the files the validator needs into a fresh directory and print its path.
fresh_copy() {
  local dir="$TMP/case-$((PASS + FAIL))"
  mkdir -p "$dir"
  cp -r "$ROOT/README.md" "$ROOT/ready-fast" "$ROOT/install.sh" "$ROOT/VERSION" \
    "$ROOT/lib" "$ROOT/scripts" "$ROOT/docs" "$ROOT/tools" "$dir/"
  printf '%s\n' "$dir"
}

# expect_failure <description> <text expected in the report> <command that breaks the docs>
expect_failure() {
  local desc="$1" expected="$2" breaker="$3" dir rc=0
  dir="$(fresh_copy)"
  (cd "$dir" && eval "$breaker")
  python3 "$dir/tools/validate-docs.py" >"$TMP/report.log" 2>&1 || rc=$?
  if [[ "$rc" -eq 1 ]] && grep -qF -- "$expected" "$TMP/report.log"; then
    PASS=$((PASS + 1))
    printf 'ok   - fails when %s\n' "$desc"
  else
    FAIL=$((FAIL + 1))
    printf 'FAIL - should fail when %s (exit status %s, expected text: %s)\n' "$desc" "$rc" "$expected"
    sed 's/^/       /' "$TMP/report.log"
  fi
}

dir="$(fresh_copy)"
if python3 "$dir/tools/validate-docs.py" >"$TMP/report.log" 2>&1; then
  PASS=$((PASS + 1))
  echo "ok   - the real documentation passes"
else
  FAIL=$((FAIL + 1))
  echo "FAIL - the real documentation passes"
  sed 's/^/       /' "$TMP/report.log"
fi

expect_failure "a Bengali translation is missing" \
  "has no Bengali translation" \
  'rm docs/bn/firewall.md'
expect_failure "an English translation is missing" \
  "has no English translation" \
  'rm docs/en/scripts/network-info.md'
expect_failure "a translation is an empty placeholder" \
  "is too short to be real documentation" \
  'echo "x" > docs/bn/backup.md'
expect_failure "a Bengali file is an untranslated copy of the English one" \
  "it looks untranslated" \
  'cp docs/en/docker.md docs/bn/docker.md'
expect_failure "a command differs between the two languages" \
  "differs from the English version" \
  'sed -i "s/ready-fast run system-monitor --disk-warn 70/ready-fast run system-monitor --disk-warn 75/" docs/bn/monitoring.md'
expect_failure "a relative link is broken" \
  "broken link: ../firewal.md" \
  'sed -i "s#(../firewall.md)#(../firewal.md)#" docs/en/scripts/docker-install.md'
expect_failure "a documented CLI command does not exist" \
  "documented CLI command does not exist: 'ready-fast check'" \
  'sed -i "s/ready-fast doctor/ready-fast check/" docs/en/quick-start.md docs/bn/quick-start.md'
expect_failure "a documented option does not exist" \
  "documented option does not exist: '--cpu-warn'" \
  'sed -i "s/run system-monitor --disk-warn 70/run system-monitor --cpu-warn 70/" docs/en/monitoring.md docs/bn/monitoring.md'
expect_failure "a documented script does not exist" \
  "documented script does not exist: 'net-info'" \
  'sed -i "s/ready-fast run network-info/ready-fast run net-info/" docs/en/networking.md docs/bn/networking.md'
expect_failure "a required section of a script document is missing" \
  "required section is missing" \
  'sed -i "/^## 11\./d" docs/bn/scripts/ssh-hardening.md'
expect_failure "the language navigation link is missing" \
  "language link to '../bn/backup.md' is missing" \
  'sed -i "3d" docs/en/backup.md'
expect_failure "a new script has no documentation" \
  "docs/bn/scripts/new-thing.md: script documentation is missing" \
  'cp scripts/network-info.sh scripts/new-thing.sh'
expect_failure "a new option is not documented" \
  "option --mail of 'firewall-setup' is not documented in section 7" \
  'sed -i "s/^  --web  .*/&\n  --mail                   Also allow SMTP/" scripts/firewall-setup.sh'
expect_failure "one language has an extra section" \
  "heading outline differs from the English version" \
  'printf "\n## Extra\n\nনতুন অংশ।\n" >> docs/bn/docker.md'
expect_failure "the root README loses a language link" \
  "README.md: must link to docs/bn/README.md" \
  'sed -i "s#(docs/bn/README.md)#(docs/bn/installation.md)#g" README.md'
expect_failure "placeholder text is left in a document" \
  "contains placeholder text" \
  'printf "\nTODO: translate this page\n" >> docs/bn/security.md'

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
if ((FAIL > 0)); then
  exit 1
fi
