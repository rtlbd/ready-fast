#!/usr/bin/env bash
# Description: Verify, list or extract a backup archive created by backup-create
# Requires-Root: depends
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
. "$SCRIPT_DIR/../lib/common.sh"

ARCHIVE=""
TARGET=""
LIST_ONLY=0

usage() {
  cat <<'USAGE'
Usage: ready-fast run backup-restore --file <archive> (--list | --target <dir>) [options]

Checks the SHA-256 checksum of a backup archive (when the .sha256 file is
next to it), then either lists its contents or extracts it into a directory.
Files are extracted with their original paths below --target, so
"--target /" puts every file back in its original place.

Options:
  --file <archive>   The .tar.gz archive to use (required)
  --list             Only list the contents of the archive; extract nothing
  --target <dir>     Directory to extract into (required unless --list is used)
  --dry-run          Show what would be done without changing anything
  --yes              Do not ask for confirmation
  --help             Show this help

Existing files in --target that have the same path as a file in the archive
are overwritten. Root permission is needed when the archive or --target is
not accessible to your user, and to restore original file owners.
USAGE
}

while (($# > 0)); do
  case "$1" in
    --file)
      rf_need_value "$1" "$#"
      ARCHIVE="$2"
      shift 2
      ;;
    --target)
      rf_need_value "$1" "$#"
      TARGET="$2"
      shift 2
      ;;
    --list)
      LIST_ONLY=1
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

if [[ -z "$ARCHIVE" ]]; then
  rf_usage_error "--file <archive> is required."
fi
if ((LIST_ONLY)) && [[ -n "$TARGET" ]]; then
  rf_usage_error "Use either --list or --target, not both."
fi
if ((!LIST_ONLY)) && [[ -z "$TARGET" ]]; then
  rf_usage_error "--target <dir> is required (or use --list to only view the contents)."
fi
if [[ ! -f "$ARCHIVE" ]]; then
  rf_die "Archive not found: $ARCHIVE"
fi
if [[ ! -r "$ARCHIVE" ]]; then
  rf_die "Archive is not readable: $ARCHIVE (try again with sudo)"
fi

ARCHIVE_ABS="$(realpath -e -- "$ARCHIVE")"
ARCHIVE_DIR="$(dirname -- "$ARCHIVE_ABS")"
ARCHIVE_BASE="$(basename -- "$ARCHIVE_ABS")"

if [[ -f "$ARCHIVE_ABS.sha256" ]]; then
  if (cd -- "$ARCHIVE_DIR" && sha256sum --check --status -- "$ARCHIVE_BASE.sha256"); then
    rf_ok "Checksum verified: $ARCHIVE_BASE"
  else
    rf_die "Checksum mismatch for $ARCHIVE_BASE. The archive is damaged or was modified; nothing was extracted."
  fi
else
  rf_warn "No checksum file found ($ARCHIVE_BASE.sha256); the archive integrity was not verified."
fi

if ((LIST_ONLY)); then
  tar --list --gzip --file "$ARCHIVE_ABS" || rf_die "tar could not read $ARCHIVE_BASE. The archive is damaged."
  exit 0
fi

TARGET_ABS="$(realpath -m -- "$TARGET")"
rf_info "Archive: $ARCHIVE_ABS"
rf_info "Target:  $TARGET_ABS"
if [[ "$TARGET_ABS" == "/" ]]; then
  rf_warn "Target is /. Files will be restored to their original locations and existing files will be overwritten."
else
  rf_warn "Existing files below $TARGET_ABS with the same paths will be overwritten."
fi
rf_confirm "Extract the archive?"

rf_run install -d "$TARGET_ABS"
rf_run tar --extract --gzip --preserve-permissions --file "$ARCHIVE_ABS" --directory "$TARGET_ABS" ||
  rf_die "tar could not extract $ARCHIVE_BASE. Some files may have been extracted into $TARGET_ABS before the error."

if ((RF_DRY_RUN)); then
  rf_ok "Dry run finished. Nothing was changed."
  exit 0
fi
rf_ok "Restore complete: files were extracted into $TARGET_ABS"
