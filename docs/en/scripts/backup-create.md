# backup-create

🌐 **English** | [বাংলা](../../bn/scripts/backup-create.md)

[← Documentation home](../README.md)

## 1. Introduction

`backup-create` packs the files and directories you choose into one compressed archive (a `.tar.gz` file) and writes a checksum file next to it. The checksum makes it possible to detect later whether the archive was damaged.

Use it before you change configuration, before an upgrade, or on a schedule. The matching script [backup-restore](backup-restore.md) brings the files back. For a complete backup routine, see [Backup](../backup.md).

## 2. What it does

- Checks that every source exists and can be read.
- Creates the destination directory if it does not exist.
- Creates the archive `<dest>/<name>-YYYYMMDD-HHMMSS.tar.gz`. The date and time in the name are taken from the server clock.
- Writes the SHA-256 checksum of the archive to a file with the same name plus `.sha256`.
- With `--keep`: deletes older archives with the same name, so that the disk does not fill up.

The source files are only read; they are never changed or deleted. File permissions, owners and symbolic links are stored in the archive.

## 3. Supported OS

| Distribution | Versions |
| --- | --- |
| Ubuntu | 22.04, 24.04, 26.04 |
| Debian | 12, 13 |

This script does not check the operating system. It should also work on other Linux distributions with GNU `tar`, but it is tested only on the systems in the table. See [Supported OS](../supported-os.md).

## 4. Requirements

- Root permission: **depends**. You need `sudo` when your user cannot read the sources (for example `/etc`) or cannot write to the destination. The default destination `/var/backups/ready-fast` needs root.
- Enough free disk space in the destination for the compressed archive.
- The standard tools `tar`, `gzip` and `sha256sum`.
- ready-fast installed (see [Installation](../installation.md)).

## 5. Installation command

Preview. This shows the commands that would run and creates nothing:

```bash
sudo ready-fast run backup-create --source /etc --name etc --dry-run
```

Back up the system configuration in `/etc`:

```bash
sudo ready-fast run backup-create --source /etc --name etc
```

Back up two directories into one archive and keep only the 7 newest archives named `web`:

```bash
sudo ready-fast run backup-create --source /etc --source /var/www --name web --keep 7
```

Back up to another disk that is mounted at `/mnt/backup`:

```bash
sudo ready-fast run backup-create --source /home/deploy/app --dest /mnt/backup --name app
```

The script does not ask for confirmation, because creating a backup does not change your data. Be careful with `--keep`: older archives are deleted without a question.

## 6. Step-by-step explanation

**Step 1 — check the sources.** Each `--source` path is converted to its full absolute path. The script stops if a source does not exist, cannot be read, or is `/` (backing up the whole root filesystem is not supported).

**Step 2 — prepare the destination.** If the destination directory does not exist, it is created so that only its owner can open it (permission `0700`). An existing directory keeps its permissions.

**Step 3 — create the archive.** For the example with `/etc`, the script runs a command like this:

```bash
tar --create --gzip --file /var/backups/ready-fast/etc-20261126-210300.tar.gz --directory / --no-wildcards --anchored --exclude var/backups/ready-fast etc
```

`--create --gzip --file` writes a compressed archive. `--directory /` together with the path `etc` stores files with paths relative to `/` (for example `etc/hostname`), which lets you restore them anywhere. The `--exclude var/backups/ready-fast` part leaves out the destination directory itself, so an archive never contains older backups when the destination lies inside a source. The archive is created readable by its owner only (permission `0600`), because backups often contain passwords and keys.

**Step 4 — write the checksum.**

```bash
sha256sum etc-20261126-210300.tar.gz
```

The result is saved as `etc-20261126-210300.tar.gz.sha256` in the same directory.

**Step 5 — retention** (only with `--keep`). The script lists the archives in the destination whose names are exactly `<name>-YYYYMMDD-HHMMSS.tar.gz`, keeps the newest ones and deletes the rest together with their `.sha256` files. Archives with other names are never touched.

If creating the archive fails, the incomplete file is deleted, so a failed run never leaves a broken backup behind.

## 7. Command options

| Option | Meaning |
| --- | --- |
| `--source <path>` | A file or directory to back up. Required. Can be given several times. |
| `--dest <dir>` | The directory that receives the archive. Default: `/var/backups/ready-fast`. |
| `--name <label>` | The first part of the archive name. Letters, digits, dot, dash and underscore are allowed. Default: `backup`. |
| `--keep <count>` | After a successful backup, keep only the newest `<count>` archives with this name in the destination and delete older ones. Default: 0, which keeps everything. |
| `--dry-run` | Show what would be done without changing anything. |
| `--help` | Show the help text and exit. |

## 8. Expected output

Output of `sudo ready-fast run backup-create --source /etc --name etc --keep 7`:

```text
[INFO] Sources: /etc
[INFO] Archive: /var/backups/ready-fast/etc-20261126-210300.tar.gz
[OK] Backup created: /var/backups/ready-fast/etc-20261126-210300.tar.gz (1.2M)
[OK] Checksum file:  /var/backups/ready-fast/etc-20261126-210300.tar.gz.sha256
[INFO] Retention: 1 archive(s) named 'etc' present, nothing to remove (keep 7).
```

When more than 7 archives exist, each deleted one is reported:

```text
[INFO] Removing old backup: /var/backups/ready-fast/etc-20261119-020000.tar.gz
```

## 9. Security considerations

- **Archives are not encrypted.** Anyone who can read the archive can read everything in it, including password hashes, private keys and database credentials. The script restricts the archive to its owner, but you must protect copies yourself.
- **A backup on the same server is not enough.** If the disk fails or the server is deleted, the backup is lost with it. Copy archives to another machine or storage service; see [Backup](../backup.md).
- `--keep` deletes old archives permanently and without confirmation. Use a different `--name` for backups that must not be rotated away.
- Databases that are running (MySQL, PostgreSQL, MongoDB and others) cannot be backed up safely by copying their data files. Create a dump with the database's own tool first, then back up the dump file.
- The script follows the path you give it. Check `--source` and `--dest` twice when you run it with `sudo`.

## 10. Side effects

- A new archive and a new `.sha256` file in the destination directory.
- The destination directory is created if it was missing.
- With `--keep`: older archives with the same name, and their `.sha256` files, are deleted.
- Disk space is used in the destination. Reading large directories causes disk activity while the backup runs.

## 11. Rollback instructions

A backup changes nothing on the system, so there is nothing to undo. To remove an archive that you do not need, delete it together with its checksum file:

```bash
sudo rm -f /var/backups/ready-fast/etc-20261126-210300.tar.gz /var/backups/ready-fast/etc-20261126-210300.tar.gz.sha256
```

Archives that were deleted by `--keep` cannot be recovered.

## 12. Troubleshooting

| Problem | Cause and solution |
| --- | --- |
| `At least one --source <path> is required.` | Add `--source` with the file or directory you want to back up. |
| `Source does not exist` | Check the path for typing mistakes. |
| `Source is not readable` or `Destination is not writable` | Run the command with `sudo`. |
| `tar failed with status 2. No backup was created.` | Read the `tar` messages above the error. The most common causes are a full disk in the destination (check with `df -h`) and unreadable files inside the source. |
| `Some files changed while they were being read.` | A program wrote to the files during the backup. The archive exists, but those files may be incomplete. Stop the program first or back up at a quiet time. For databases, back up a dump instead. |
| `already exists. Wait one second and try again.` | Two backups with the same name were started within the same second. Run the command again. |
| `Invalid --name value` | Use only letters, digits, dot, dash and underscore in the name. |
| The disk fills up with backups | Use `--keep` and check old archives with `ls -lh /var/backups/ready-fast` (as root). |

More general problems are covered in [Troubleshooting](../troubleshooting.md).

## 13. Testing status

| What | How it is tested |
| --- | --- |
| Shell syntax and common mistakes | `shellcheck` in CI on every push |
| Option validation, `--dry-run`, archive and checksum creation, archive permissions, exclusion of the destination, retention with `--keep`, restoring and comparing the files | `tests/smoke.sh` in CI, on a GitHub-hosted Ubuntu virtual machine and inside `amd64` containers of Ubuntu 22.04, 24.04, 26.04 and Debian 12, 13 |
| Very large directories, special files (devices, sockets), a full disk | Not tested automatically |
| `arm64` | Not tested |

A backup is only proven when a restore has worked. Test your own backups with [backup-restore](backup-restore.md).
