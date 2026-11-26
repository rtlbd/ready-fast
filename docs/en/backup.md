# Backup

🌐 **English** | [বাংলা](../bn/backup.md)

[← Documentation home](README.md)

Sooner or later every server loses data: a wrong command, a failed disk, a hacked website, an unpaid invoice. A backup turns such a day from a disaster into an inconvenience. This guide shows a simple backup routine with ready-fast.

The two scripts behind this guide are documented in [backup-create](scripts/backup-create.md) and [backup-restore](scripts/backup-restore.md).

## Three rules for backups that work

1. **Back up what you cannot recreate.** Configuration, website files, uploaded content and database dumps.
2. **Keep a copy somewhere else.** A backup that lies only on the same server disappears together with the server.
3. **Test the restore.** A backup that has never been restored is only a hope.

## What to back up

| Path | What it usually contains | Back it up? |
| --- | --- | --- |
| `/etc` | System and service configuration | Yes |
| `/var/www` | Website files | Yes, if you host websites |
| `/home` | Files of the users | Yes, if they matter |
| Your application directory | Code, uploads, configuration | Yes |
| A directory with database dumps | Exported databases (see below) | Yes |
| `/proc`, `/sys`, `/dev`, `/run`, `/tmp` | Virtual and temporary files | No |
| `/var/lib/docker` | Raw Docker data | No. Back up your Compose files and volume data instead. |

Backing up the whole system (`/`) is not supported by ready-fast. For a full image of the server, use the snapshot feature of your hosting provider in addition to these file backups.

## Create a backup

Preview, then run:

```bash
sudo ready-fast run backup-create --source /etc --source /var/www --name web --dry-run
sudo ready-fast run backup-create --source /etc --source /var/www --name web
```

- Root permission: required here, because `/etc` contains files that only root can read and the default destination belongs to root.
- Risk: none for your data; the sources are only read. The archive uses disk space in `/var/backups/ready-fast`.

The result is an archive such as `web-20261126-023000.tar.gz` and a checksum file with the same name plus `.sha256`.

## Databases need a dump first

Do not back up the data directory of a running database (for example `/var/lib/mysql`). The files change while they are copied, and the copy may be unusable. Export the database to a file first, then back up that file.

Example for MySQL or MariaDB on a server where `root` can connect to the database without a password, which is the default on Ubuntu and Debian:

```bash
sudo mkdir -p /var/backups/db
sudo sh -c 'mysqldump --all-databases > /var/backups/db/mysql-all.sql'
sudo ready-fast run backup-create --source /var/backups/db --name db --keep 7
```

- The first line creates a directory for the dump.
- The second line exports all databases into one file.
- The third line backs up that directory and keeps the 7 newest archives.

PostgreSQL has the tool `pg_dumpall` for the same purpose. Follow the documentation of your database.

## Keep the disk from filling up

Each run creates a new archive. With `--keep`, older archives with the same name are deleted after a successful backup:

```bash
sudo ready-fast run backup-create --source /etc --source /var/www --name web --keep 14
```

**Warning:** deleted archives cannot be recovered, and the script does not ask before deleting. Archives with a different `--name` are never touched, so use a separate name for a backup that you want to keep for good.

## Back up automatically every night

Open the schedule of the root user:

```bash
sudo crontab -e
```

Add this line at the end, then save and close the editor:

```cron
30 2 * * * /usr/local/bin/ready-fast run backup-create --source /etc --source /var/www --name web --keep 14 >> /var/log/ready-fast-backup.log 2>&1
```

- `30 2 * * *` means "every day at 02:30", in the time zone of the server.
- The full path `/usr/local/bin/ready-fast` is used because cron knows only a few directories.
- The end of the line writes the output to the log file `/var/log/ready-fast-backup.log`.

Check on the next day that a new archive exists:

```bash
sudo ls -lh /var/backups/ready-fast
```

To stop the automatic backup, run `sudo crontab -e` again and delete the line.

## Keep a copy away from the server

Choose at least one of these:

- **Another machine.** Push the backup directory to a second server or a computer at your office with `rsync`. In this example, `backup@203.0.113.20` is a user on the other machine that your server can reach with an SSH key:

```bash
sudo rsync -a /var/backups/ready-fast/ backup@203.0.113.20:backups/web-01/
```

  `-a` keeps permissions and times. The `/` at the end of the source path means "the contents of this directory". `rsync` must be installed on both machines.

- **Another disk.** If a second disk or network storage is mounted on the server, write backups there directly with `--dest`, as shown in [backup-create](scripts/backup-create.md).
- **Provider snapshots.** Useful in addition, but they usually live in the same account and data centre as the server.

Archives are **not encrypted**. Everything that leaves the server should be encrypted first, for example with `gpg --symmetric`, and the passphrase must be stored somewhere safe that is not the server.

## Test a restore

Do this after you set up your backups, and then every few months.

**1. Check the archive and look inside:**

```bash
sudo ready-fast run backup-restore --file /var/backups/ready-fast/web-20261126-023000.tar.gz --list
```

The first line of the output must be `[OK] Checksum verified`.

**2. Extract it into a test directory:**

```bash
sudo ready-fast run backup-restore --file /var/backups/ready-fast/web-20261126-023000.tar.gz --target /tmp/restore-test
```

**3. Compare a file with the original and clean up:**

```bash
sudo diff /etc/hostname /tmp/restore-test/etc/hostname
sudo rm -rf /tmp/restore-test
```

`diff` prints nothing when the two files are identical.

## Restore after a mistake

When a file was damaged or deleted, do not restore the whole archive over the system. Extract it into a test directory as shown above and copy back only the file you need:

```bash
sudo cp -a /tmp/restore-test/etc/hostname /etc/hostname
```

`cp -a` keeps the owner and permissions of the file. Restoring everything in place with `--target /` overwrites current files and cannot be undone; read the security section of [backup-restore](scripts/backup-restore.md) before you do that.

## Limits of these backups

- No encryption. Protect the archives yourself.
- No incremental backups. Every archive is a full copy, so large directories need a lot of space.
- No consistent copy of running databases. Use dumps.
- No full-system or bare-metal recovery.
- No automatic copy to another machine. You must set that up yourself.

## More help

Error messages are explained in [backup-create](scripts/backup-create.md) and [backup-restore](scripts/backup-restore.md). General help is in [Troubleshooting](troubleshooting.md).
