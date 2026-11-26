#!/usr/bin/env bash
# Description: Create a compressed tar.gz backup of files or directories, with a SHA-256 checksum
# Requires-Root: depends
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
. "$SCRIPT_DIR/../lib/common.sh"

SOURCES=()
DEST="$RF_BACKUP_ROOT"
NAME="backup"
KEEP=0

usage() {
  cat <<'USAGE'
Usage: ready-fast run backup-create --source <path> [options]

Creates <dest>/<name>-YYYYMMDD-HHMMSS.tar.gz from the given files or
directories and writes a SHA-256 checksum file next to it. The source files
are only read, never changed.

Options:
  --source <path>   File or directory to back up (repeatable, at least one required)
  --dest <dir>      Directory that receives the archive (default: /var/backups/ready-fast)
  --name <label>    Archive name prefix: letters, digits, dot, dash, underscore (default: backup)
  --keep <count>    After a successful backup, keep only the newest <count> archives
                    with this name in --dest and delete older ones (default: 0 = keep all)
  --dry-run         Show what would be done without changing anything
  --help            Show this help

Root permission is needed when the sources are not readable by your user or
when --dest is not writable by your user (the default --dest needs root).
USAGE
}

while (($# > 0)); do
  case "$1" in
    --source)
      rf_need_value "$1" "$#"
      SOURCES+=("$2")
      shift 2
      ;;
    --dest)
      rf_need_value "$1" "$#"
      DEST="$2"
      shift 2
      ;;
    --name)
      rf_need_value "$1" "$#"
      NAME="$2"
      shift 2
      ;;
    --keep)
      rf_need_value "$1" "$#"
      KEEP="$2"
      shift 2
      ;;
    --dry-run)
      RF_DRY_RUN=1
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

if ((${#SOURCES[@]} == 0)); then
  rf_usage_error "At least one --source <path> is required."
fi
if [[ ! "$NAME" =~ ^[A-Za-z0-9._-]+$ ]]; then
  rf_usage_error "Invalid --name value: $NAME (allowed: letters, digits, dot, dash, underscore)"
fi
if [[ ! "$KEEP" =~ ^[0-9]{1,4}$ ]]; then
  rf_usage_error "Invalid --keep value: $KEEP (expected a number from 0 to 9999)"
fi
KEEP=$((10#$KEEP))
if [[ -z "$DEST" ]]; then
  rf_usage_error "--dest must not be empty."
fi

# Resolve every source to an absolute path and store it relative to "/".
MEMBERS=()
for source in "${SOURCES[@]}"; do
  if [[ ! -e "$source" ]]; then
    rf_die "Source does not exist: $source"
  fi
  resolved="$(realpath -e -- "$source")"
  if [[ "$resolved" == "/" ]]; then
    rf_die "Backing up the whole root filesystem (/) is not supported. Choose specific directories."
  fi
  if [[ ! -r "$resolved" ]]; then
    rf_die "Source is not readable: $resolved (try again with sudo)"
  fi
  MEMBERS+=("${resolved#/}")
done

DEST_ABS="$(realpath -m -- "$DEST")"
if [[ "$DEST_ABS" == "/" ]]; then
  rf_usage_error "--dest must not be the root directory."
fi
ARCHIVE="$DEST_ABS/$NAME-$(rf_timestamp).tar.gz"
CHECKSUM="$ARCHIVE.sha256"

rf_info "Sources: ${MEMBERS[*]/#//}"
rf_info "Archive: $ARCHIVE"

if ((RF_DRY_RUN)); then
  rf_run install -d -m 0700 "$DEST_ABS"
  rf_run tar --create --gzip --file "$ARCHIVE" --directory / \
    --no-wildcards --anchored --exclude "${DEST_ABS#/}" "${MEMBERS[@]}"
  rf_run sha256sum "$ARCHIVE"
else
  if [[ -e "$ARCHIVE" ]]; then
    rf_die "$ARCHIVE already exists. Wait one second and try again."
  fi
  if [[ ! -d "$DEST_ABS" ]]; then
    install -d -m 0700 "$DEST_ABS" || rf_die "Cannot create $DEST_ABS (try again with sudo)."
  fi
  if [[ ! -w "$DEST_ABS" ]]; then
    rf_die "Destination is not writable: $DEST_ABS (try again with sudo)"
  fi

  cleanup_partial() { rm -f -- "$ARCHIVE" "$CHECKSUM"; }
  trap cleanup_partial ERR INT TERM

  # Archives may contain passwords and keys, so only the owner may read them.
  umask 077
  tar_status=0
  tar --create --gzip --file "$ARCHIVE" --directory / \
    --no-wildcards --anchored --exclude "${DEST_ABS#/}" "${MEMBERS[@]}" || tar_status=$?
  if ((tar_status == 1)); then
    rf_warn "Some files changed while they were being read. The archive was created, but those files may be inconsistent."
  elif ((tar_status > 1)); then
    cleanup_partial
    rf_die "tar failed with status $tar_status. No backup was created."
  fi

  (cd -- "$DEST_ABS" && sha256sum -- "$(basename -- "$ARCHIVE")" >"$(basename -- "$CHECKSUM")")
  trap - ERR INT TERM

  rf_ok "Backup created: $ARCHIVE ($(du -h -- "$ARCHIVE" | cut -f1))"
  rf_ok "Checksum file:  $CHECKSUM"
fi

if ((KEEP > 0)); then
  mapfile -t archives < <(
    find "$DEST_ABS" -maxdepth 1 -type f -name "$NAME-*.tar.gz" 2>/dev/null |
      grep -E "/${NAME//./\\.}-[0-9]{8}-[0-9]{6}\.tar\.gz$" | sort -r || true
  )
  if ((${#archives[@]} > KEEP)); then
    for old in "${archives[@]:KEEP}"; do
      rf_info "Removing old backup: $old"
      rf_run rm -f -- "$old" "$old.sha256"
    done
  else
    rf_info "Retention: ${#archives[@]} archive(s) named '$NAME' present, nothing to remove (keep $KEEP)."
  fi
fi

if ((RF_DRY_RUN)); then
  rf_ok "Dry run finished. Nothing was changed."
fi
