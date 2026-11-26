# ⚡ ready-fast

🌐 **English** | [বাংলা](../bn/README.md)

[← Project home](../../README.md)

**One Command. Everything Ready.**

A ready-to-run automation toolkit for Linux server setup, Docker, networking, security, monitoring, and DevOps.

ready-fast is a small collection of carefully written shell scripts with one simple command in front of them. Each script does one job on an Ubuntu or Debian server, explains what it is going to do, and can show you a preview before anything is changed.

## Who is this for

- People who are learning Linux and want to see safe, explained commands.
- Owners of a VPS or dedicated server who want a secure basic setup quickly.
- Web developers who need Docker and a firewall without reading ten tutorials.
- System administrators, network administrators and DevOps engineers who want repeatable, reviewable steps.

## Start here

1. [Installation](installation.md) — download and install ready-fast.
2. [Quick start](quick-start.md) — your first ten minutes, step by step.
3. [Command reference](commands.md) — every command and every option.

## Scripts

| Script | What it does | Root needed |
| --- | --- | --- |
| [docker-install](scripts/docker-install.md) | Installs Docker Engine and the Compose plugin from Docker's official repository. | Yes |
| [firewall-setup](scripts/firewall-setup.md) | Turns on the UFW firewall, keeps SSH open and allows the ports you choose. | Yes |
| [ssh-hardening](scripts/ssh-hardening.md) | Applies safer SSH server settings, with a one-command rollback. | Yes |
| [network-info](scripts/network-info.md) | Shows IP addresses, routes, DNS servers and listening ports. Read-only. | No |
| [system-monitor](scripts/system-monitor.md) | Reports CPU load, memory, disk usage and failed services. Read-only. | No |
| [backup-create](scripts/backup-create.md) | Creates a compressed backup archive with a checksum. | Depends |
| [backup-restore](scripts/backup-restore.md) | Verifies, lists or extracts a backup archive. | Depends |

Every script document has the same 13 sections: introduction, what it does, supported OS, requirements, installation command, step-by-step explanation, options, expected output, security considerations, side effects, rollback, troubleshooting and testing status.

## Guides by topic

| Guide | What you will learn |
| --- | --- |
| [Docker](docker.md) | Installing Docker, the first container, using Docker without `sudo`, updating and removing it. |
| [Networking](networking.md) | Reading the network report and finding common network problems. |
| [Firewall](firewall.md) | How UFW works, typical rule sets, and the Docker caveat. |
| [Security](security.md) | How ready-fast keeps you safe and a hardening checklist for a new server. |
| [Monitoring](monitoring.md) | Understanding load, memory and disk numbers; running checks from cron. |
| [Backup](backup.md) | A backup routine, retention, off-server copies and restore tests. |
| [Supported OS](supported-os.md) | Which systems are supported and how that is checked. |
| [Troubleshooting](troubleshooting.md) | Solutions for common errors and how to report a problem. |

## Safety rules that every script follows

- **Preview first.** Scripts that change anything accept `--dry-run`, which prints every step and changes nothing.
- **Ask before changing.** Scripts that change system settings or overwrite files show a summary and wait for your `y`. Without a terminal they stop, unless you pass `--yes`.
- **Refuse unknown systems.** Scripts that install software or change system settings stop on an operating system that is not supported.
- **Say when root is needed.** Each document states clearly whether `sudo` is required.
- **Be undoable.** Each document has rollback instructions. Files that a script replaces are copied to `/var/backups/ready-fast` first.
- **No surprises.** No script sends usage data anywhere. The only internet connections are the ones described in each document.

## Supported systems

Ubuntu 22.04, 24.04 and 26.04, and Debian 12 and 13, on `amd64` and `arm64`. Details are in [Supported OS](supported-os.md).

## Keeping both languages in sync

This documentation exists in English and in Bengali, and both must always describe the same behaviour. The rules for contributors are:

- When a script changes, update its document in `docs/en/scripts/` and in `docs/bn/scripts/` in the same change.
- When a CLI command or option changes, update `commands.md` in both languages.
- When a new feature or script is added, document it in both languages before it is merged.
- Never translate commands, package names, file paths, environment variables, configuration keys or program output. Translate only the explanation around them.

These rules are enforced automatically. Run the check before every commit:

```bash
python3 tools/validate-docs.py
```

The same check runs in GitHub Actions on every push and pull request. It fails when a translation is missing, when the code blocks of the two languages differ, when a link is broken, or when a documented command or option does not exist.
