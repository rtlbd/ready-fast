#!/usr/bin/env bash
# Description: Report CPU load, memory, disk usage and failed services, with warning thresholds (read-only)
# Requires-Root: no
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
. "$SCRIPT_DIR/../lib/common.sh"

DISK_WARN=85
MEM_WARN=90

usage() {
  cat <<'USAGE'
Usage: ready-fast run system-monitor [options]

Prints a read-only health report: uptime, CPU load, memory, swap, disk usage,
failed systemd services and the busiest processes. Nothing on the system is
changed. The exit status is 1 when at least one warning is reported, so the
script can be used from cron or other automation.

Warnings are raised when:
  - the 1-minute load average is higher than the number of CPU cores
  - memory usage reaches the --mem-warn threshold
  - any filesystem reaches the --disk-warn threshold
  - a systemd service is in the "failed" state

Options:
  --disk-warn <percent>   Disk usage warning threshold, 1-100 (default: 85)
  --mem-warn <percent>    Memory usage warning threshold, 1-100 (default: 90)
  --help                  Show this help

Root permission is not required.
USAGE
}

valid_percent() {
  [[ "$1" =~ ^[0-9]{1,3}$ ]] && ((10#$1 >= 1 && 10#$1 <= 100))
}

while (($# > 0)); do
  case "$1" in
    --disk-warn)
      rf_need_value "$1" "$#"
      DISK_WARN="$2"
      shift 2
      ;;
    --mem-warn)
      rf_need_value "$1" "$#"
      MEM_WARN="$2"
      shift 2
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

if ! valid_percent "$DISK_WARN"; then
  rf_usage_error "Invalid --disk-warn value: $DISK_WARN (expected a number from 1 to 100)"
fi
if ! valid_percent "$MEM_WARN"; then
  rf_usage_error "Invalid --mem-warn value: $MEM_WARN (expected a number from 1 to 100)"
fi
DISK_WARN=$((10#$DISK_WARN))
MEM_WARN=$((10#$MEM_WARN))

WARNINGS=0

section() { printf '\n== %s ==\n' "$1"; }

warn_line() {
  printf 'WARNING: %s\n' "$*"
  WARNINGS=$((WARNINGS + 1))
}

section "System"
printf 'Hostname: %s\n' "$(hostname)"
printf 'Kernel:   %s\n' "$(uname -r)"
uptime_seconds="$(cut -d. -f1 /proc/uptime)"
printf 'Uptime:   %s day(s), %s hour(s), %s minute(s)\n' \
  "$((uptime_seconds / 86400))" "$((uptime_seconds % 86400 / 3600))" "$((uptime_seconds % 3600 / 60))"

section "CPU load"
cores="$(nproc)"
read -r load1 load5 load15 _rest </proc/loadavg
printf 'CPU cores: %s\n' "$cores"
printf 'Load average (1, 5, 15 min): %s %s %s\n' "$load1" "$load5" "$load15"
if awk -v load="$load1" -v cores="$cores" 'BEGIN { exit !(load > cores) }'; then
  warn_line "1-minute load average $load1 is higher than the number of CPU cores ($cores)"
fi

section "Memory"
mem_total_kb="$(awk '$1 == "MemTotal:" { print $2 }' /proc/meminfo)"
mem_avail_kb="$(awk '$1 == "MemAvailable:" { print $2 }' /proc/meminfo)"
swap_total_kb="$(awk '$1 == "SwapTotal:" { print $2 }' /proc/meminfo)"
swap_free_kb="$(awk '$1 == "SwapFree:" { print $2 }' /proc/meminfo)"
mem_used_kb=$((mem_total_kb - mem_avail_kb))
mem_percent=$((mem_used_kb * 100 / mem_total_kb))
printf 'Memory: %s MiB used of %s MiB (%s%%)\n' "$((mem_used_kb / 1024))" "$((mem_total_kb / 1024))" "$mem_percent"
if ((swap_total_kb > 0)); then
  printf 'Swap:   %s MiB used of %s MiB\n' "$(((swap_total_kb - swap_free_kb) / 1024))" "$((swap_total_kb / 1024))"
else
  printf 'Swap:   not configured\n'
fi
if ((mem_percent >= MEM_WARN)); then
  warn_line "memory usage is ${mem_percent}% (threshold ${MEM_WARN}%)"
fi

section "Disk usage"
disk_report="$(df -P -l -x tmpfs -x devtmpfs -x squashfs -x efivarfs 2>/dev/null || true)"
printf '%s\n' "$disk_report"
while read -r _fs _blocks _used _avail capacity mount; do
  percent="${capacity%\%}"
  if [[ "$percent" =~ ^[0-9]+$ ]] && ((percent >= DISK_WARN)); then
    warn_line "filesystem $mount is ${percent}% full (threshold ${DISK_WARN}%)"
  fi
done < <(printf '%s\n' "$disk_report" | tail -n +2)

section "Failed services"
if rf_systemd_running; then
  failed_units="$(systemctl --failed --no-legend --plain 2>/dev/null | awk '{ print $1 }')"
  if [[ -n "$failed_units" ]]; then
    printf '%s\n' "$failed_units"
    warn_line "$(printf '%s\n' "$failed_units" | wc -l) systemd unit(s) in failed state"
  else
    echo "none"
  fi
else
  echo "(systemd is not running; skipped)"
fi

section "Top processes by CPU"
if rf_has_cmd ps; then
  # awk reads the whole list, so ps never receives SIGPIPE on busy servers.
  ps -eo pid,comm,%cpu,%mem --sort=-%cpu | awk 'NR <= 6'
else
  echo "(the 'ps' command is missing; install the procps package)"
fi

printf '\n'
if ((WARNINGS > 0)); then
  rf_warn "Result: $WARNINGS warning(s)."
  exit 1
fi
rf_ok "Result: no warnings."
