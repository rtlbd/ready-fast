# backup-restore

🌐 **English** | [বাংলা](../../bn/scripts/backup-restore.md)

[← Documentation home](../README.md)

## 1. Introduction

`backup-restore` works with archives made by [backup-create](backup-create.md). It can check that an archive is undamaged, show what is inside it, and extract the files into a directory of your choice.

The safe way to restore is to extract into an empty test directory first, look at the files, and copy back only what you need. Restoring directly over a live system is possible, but it overwrites files and cannot be undone. For the full routine, see [Backup](../backup.md).

## 2. What it does

- Checks that the archive exists and can be read.
- Verifies the SHA-256 checksum when the `.sha256` file lies next to the archive. If the checksum does not match, the script stops and extracts nothing.
- With `--list`: prints the paths of all files in the archive and exits.
- With `--target`: asks for confirmation, creates the target directory if needed and extracts the archive into it.

Files keep the path they had on the original system, below the target directory. A file that was `/etc/hostname` is extracted to `<target>/etc/hostname`.

## 3. Supported OS

| Distribution | Versions |
| --- | --- |
| Ubuntu | 22.04, 24.04, 26.04 |
| Debian | 12, 13 |

This script does not check the operating system. It should also work on other Linux distributions with GNU `tar`, but it is tested only on the systems in the table. See [Supported OS](../supported-os.md).

## 4. Requirements

- Root permission: **depends**. You need `sudo` when your user cannot read the archive (archives in `/var/backups/ready-fast` belong to root), cannot write to the target, or when the original file owners must be restored.
- Enough free disk space in the target for the uncompressed files.
- The standard tools `tar`, `gzip` and `sha256sum`.
- ready-fast installed (see [Installation](../installation.md)).

## 5. Installation command

Check an archive and show its contents. Nothing is extracted:

```bash
sudo ready-fast run backup-restore --file /var/backups/ready-fast/etc-20261126-210300.tar.gz --list
```

Recommended: extract into a separate test directory:

```bash
sudo ready-fast run backup-restore --file /var/backups/ready-fast/etc-20261126-210300.tar.gz --target /tmp/restore-test
```

Then copy back only the file you need, for example:

```bash
sudo cp -a /tmp/restore-test/etc/hostname /etc/hostname
```

Restore everything to its original place. **This overwrites existing files:**

```bash
sudo ready-fast run backup-restore --file /var/backups/ready-fast/etc-20261126-210300.tar.gz --target /
```

Before extracting, the script asks `Extract the archive? [y/N]:`.

## 6. Step-by-step explanation

**Step 1 — verify the checksum.** If a file with the name of the archive plus `.sha256` exists in the same directory, the script runs:

```bash
sha256sum --check --status etc-20261126-210300.tar.gz.sha256
```

This recalculates the checksum of the archive and compares it with the stored one. A mismatch means the archive was damaged or changed after the backup, and the script stops. If there is no `.sha256` file, a warning is shown and the script continues.

**Step 2 — list** (only with `--list`).

```bash
tar --list --gzip --file /var/backups/ready-fast/etc-20261126-210300.tar.gz
```

**Step 3 — confirm.** The script shows the archive and the target, warns that files with the same paths will be overwritten, and waits for your answer.

**Step 4 — extract** (only with `--target`).

```bash
install -d /tmp/restore-test
tar --extract --gzip --preserve-permissions --file /var/backups/ready-fast/etc-20261126-210300.tar.gz --directory /tmp/restore-test
```

The first line creates the target directory if it does not exist. The second extracts all files below it and restores their permissions. When run as root, the original owners are restored too.

## 7. Command options

| Option | Meaning |
| --- | --- |
| `--file <archive>` | The `.tar.gz` archive to use. Required. |
| `--list` | Only list the contents of the archive; extract nothing. Cannot be combined with `--target`. |
| `--target <dir>` | The directory to extract into. Required unless `--list` is used. |
| `--dry-run` | Show what would be done without changing anything. The checksum is still verified. |
| `--yes` | Do not ask for confirmation. |
| `--help` | Show the help text and exit. |

## 8. Expected output

Listing an archive:

```text
[OK] Checksum verified: etc-20261126-210300.tar.gz
etc/
etc/hostname
etc/hosts
...
```

Extracting into a test directory:

```text
[OK] Checksum verified: etc-20261126-210300.tar.gz
[INFO] Archive: /var/backups/ready-fast/etc-20261126-210300.tar.gz
[INFO] Target:  /tmp/restore-test
[WARN] Existing files below /tmp/restore-test with the same paths will be overwritten.
Extract the archive? [y/N]: y
[OK] Restore complete: files were extracted into /tmp/restore-test
```

A damaged archive:

```text
[ERROR] Checksum mismatch for etc-20261126-210300.tar.gz. The archive is damaged or was modified; nothing was extracted.
```

## 9. Security considerations

- **Restoring overwrites files.** Every file in the target that has the same path as a file in the archive is replaced. There is no undo. Prefer a separate target directory.
- **Be very careful with `--target /`.** Restoring an old `/etc` over a running system can bring back outdated passwords, SSH settings, firewall rules and network configuration, and can lock you out. Never restore the `/etc` of one server onto a different server.
- Only restore archives that you created yourself or that come from a source you trust. An archive can contain any file, including programs and configuration that run with root rights after a restore.
- The checksum protects against accidental damage. It does not prove who created the archive: someone who can change the archive can also change the `.sha256` file.
- Restored files are not encrypted. A test directory such as `/tmp/restore-test` contains the same secrets as the backup; delete it when you are done.

## 10. Side effects

- With `--list` or `--dry-run`: none.
- With `--target`: the target directory is created if it was missing, and the files of the archive are written below it. Existing files with the same paths are overwritten.
- Files in the target that are not in the archive are left alone. A restore does not delete anything, so it does not make the target identical to the backup.

## 11. Rollback instructions

A restore cannot be undone automatically, so prepare before you restore over existing files. Make a fresh backup of the current state first:

```bash
sudo ready-fast run backup-create --source /etc --name etc-before-restore
```

If the restore causes problems, restore that archive in the same way.

If you extracted into a test directory, undo it by deleting the directory:

```bash
sudo rm -rf /tmp/restore-test
```

## 12. Troubleshooting

| Problem | Cause and solution |
| --- | --- |
| `Archive not found` | Check the path given to `--file`. List the available archives with `sudo ls -lh /var/backups/ready-fast`. |
| `Archive is not readable` | Run the command with `sudo`. |
| `Checksum mismatch` | The archive is damaged or was changed. Use another copy of this backup or an older archive. Do not try to restore from this file. |
| `No checksum file found` | The `.sha256` file was not copied together with the archive. The restore continues, but the archive is not verified. Always keep the two files together. |
| `--target <dir> is required` | Add `--target` with a directory, or use `--list` to only look at the contents. |
| `Confirmation is required but no terminal is attached.` | The command runs without a terminal, for example from a script. Add `--yes` if you are sure. |
| `tar could not extract` | Read the `tar` messages above the error. Common causes are a full disk in the target and missing write permission. Some files may already have been extracted. |
| Restored files belong to the wrong user | The archive was extracted without root. Run the restore with `sudo` to restore the original owners. |

More general problems are covered in [Troubleshooting](../troubleshooting.md).

## 13. Testing status

| What | How it is tested |
| --- | --- |
| Shell syntax and common mistakes | `shellcheck` in CI on every push |
| Option validation, checksum verification, `--list`, `--dry-run`, confirmation without a terminal, extraction, identical file contents and permissions, rejection of a damaged archive | `tests/smoke.sh` in CI, on a GitHub-hosted Ubuntu virtual machine and inside `amd64` containers of Ubuntu 22.04, 24.04, 26.04 and Debian 12, 13 |
| Restoring to `/` on a live system | Not tested automatically |
| `arm64` | Not tested |
