# Command reference

🌐 **English** | [বাংলা](../bn/commands.md)

[← Documentation home](README.md)

This page lists every command of the `ready-fast` program, every script and every option. Commands, script names and options are written exactly as you must type them.

## Syntax

```bash
ready-fast <command> [arguments]
```

`<command>` is one of the words in the table below. Use `sudo` in front of the whole line when a script needs root permission.

## Commands

| Command | What it does | Root needed |
| --- | --- | --- |
| `ready-fast list` | Shows all available scripts. | No |
| `ready-fast run <script> [options]` | Runs a script. | Depends on the script |
| `ready-fast info <script>` | Shows the help text of a script. | No |
| `ready-fast doctor` | Checks whether this system is supported and ready. | No |
| `ready-fast version` | Shows the installed version. | No |
| `ready-fast help` | Shows a short overview of all commands. | No |

### ready-fast list

```bash
ready-fast list
```

Prints one line per script with three columns: the name (`SCRIPT`), whether root is needed (`ROOT`: `yes`, `no` or `depends`) and a one-line description (`DESCRIPTION`). The full output is shown in [Quick start](quick-start.md).

### ready-fast run

```bash
sudo ready-fast run docker-install --dry-run
```

Runs the script whose name follows `run`. Everything after the script name is passed to the script as its options. If the name is unknown, the command stops with exit status 2 and tells you to use `ready-fast list`.

### ready-fast info

```bash
ready-fast info firewall-setup
```

Prints the built-in help of a script: what it does and which options it accepts. It gives the same result as running the script with `--help`. Nothing is changed.

### ready-fast doctor

```bash
ready-fast doctor
```

Shows the operating system, the CPU architecture, whether you are root, whether systemd is running, and which required and optional tools are installed. The exit status is 0 when the system is ready, and 1 when the operating system or architecture is not supported or a required tool is missing. Example output is in [Installation](installation.md).

### ready-fast version

```bash
ready-fast version
```

```text
ready-fast 0.1.0
```

### ready-fast help

```bash
ready-fast help
```

Prints the list of commands with a few examples. Running `ready-fast` without any command shows the same text.

## Scripts and their options

Each script has its own page with full explanations. This section is the short reference.

### docker-install

Installs Docker Engine and the Compose plugin. Root needed: yes. Full page: [docker-install](scripts/docker-install.md).

```bash
sudo ready-fast run docker-install --user deploy
```

| Option | Meaning |
| --- | --- |
| `--user <name>` | Also add this existing user to the `docker` group. |
| `--dry-run` | Show what would be done without changing anything. |
| `--yes` | Do not ask for confirmation. |
| `--help` | Show the help text. |

### firewall-setup

Configures the UFW firewall. Root needed: yes. Full page: [firewall-setup](scripts/firewall-setup.md).

```bash
sudo ready-fast run firewall-setup --ssh-port 2222 --web --allow 51820/udp
```

| Option | Meaning |
| --- | --- |
| `--ssh-port <port>` | SSH port to keep open. Default: detected automatically, otherwise 22. |
| `--web` | Also allow HTTP (80/tcp) and HTTPS (443/tcp). |
| `--allow <port[/proto]>` | Also allow this port; `proto` is `tcp` or `udp`. Can be repeated. |
| `--dry-run` | Show what would be done without changing anything. |
| `--yes` | Do not ask for confirmation. |
| `--help` | Show the help text. |

### ssh-hardening

Applies safer SSH server settings. Root needed: yes. Full page: [ssh-hardening](scripts/ssh-hardening.md).

```bash
sudo ready-fast run ssh-hardening --root-login prohibit-password --disable-password-auth
sudo ready-fast run ssh-hardening --rollback
```

| Option | Meaning |
| --- | --- |
| `--root-login <mode>` | Set `PermitRootLogin` to `yes`, `prohibit-password` or `no`. |
| `--disable-password-auth` | Turn off password logins; only SSH keys work. |
| `--rollback` | Remove the settings written by this script and reload SSH. |
| `--dry-run` | Show what would be done without changing anything. |
| `--yes` | Do not ask for confirmation. |
| `--help` | Show the help text. |

### network-info

Shows the network configuration. Read-only. Root needed: no. Full page: [network-info](scripts/network-info.md).

```bash
ready-fast run network-info --public-ip --check
```

| Option | Meaning |
| --- | --- |
| `--public-ip` | Also show the public IP address (one request to `https://api.ipify.org`). |
| `--check` | Also test DNS resolution and outgoing HTTPS. |
| `--help` | Show the help text. |

### system-monitor

Prints a health report. Read-only. Root needed: no. Full page: [system-monitor](scripts/system-monitor.md).

```bash
ready-fast run system-monitor --disk-warn 80 --mem-warn 85
```

| Option | Meaning |
| --- | --- |
| `--disk-warn <percent>` | Disk usage warning threshold, 1–100. Default: 85. |
| `--mem-warn <percent>` | Memory usage warning threshold, 1–100. Default: 90. |
| `--help` | Show the help text. |

### backup-create

Creates a compressed backup archive with a checksum. Root needed: depends on the files. Full page: [backup-create](scripts/backup-create.md).

```bash
sudo ready-fast run backup-create --source /etc --dest /var/backups/ready-fast --name etc --keep 7
```

| Option | Meaning |
| --- | --- |
| `--source <path>` | File or directory to back up. Required; can be repeated. |
| `--dest <dir>` | Directory that receives the archive. Default: `/var/backups/ready-fast`. |
| `--name <label>` | First part of the archive name. Default: `backup`. |
| `--keep <count>` | Keep only the newest `<count>` archives with this name. Default: 0 (keep all). |
| `--dry-run` | Show what would be done without changing anything. |
| `--help` | Show the help text. |

### backup-restore

Verifies, lists or extracts a backup archive. Root needed: depends on the files. Full page: [backup-restore](scripts/backup-restore.md).

```bash
sudo ready-fast run backup-restore --file /var/backups/ready-fast/etc-20261126-210300.tar.gz --list
sudo ready-fast run backup-restore --file /var/backups/ready-fast/etc-20261126-210300.tar.gz --target /tmp/restore-test
```

| Option | Meaning |
| --- | --- |
| `--file <archive>` | The archive to use. Required. |
| `--list` | Only list the contents; extract nothing. |
| `--target <dir>` | Directory to extract into. Required unless `--list` is used. |
| `--dry-run` | Show what would be done without changing anything. |
| `--yes` | Do not ask for confirmation. |
| `--help` | Show the help text. |

## Options shared by several scripts

| Option | Available in | Meaning |
| --- | --- | --- |
| `--help` | Every script | Prints the help text and exits. Works without root and on any system. |
| `--dry-run` | Every script that changes something | Prints each command with the mark `[DRY-RUN]` instead of running it. Checks that only read information still run. Scripts that need root also need it for `--dry-run`. |
| `--yes` | `docker-install`, `firewall-setup`, `ssh-hardening`, `backup-restore` | Skips the confirmation question. Without a terminal (for example in cron or in another script) these scripts refuse to continue unless `--yes` is given. |

## Exit status

Every command and script ends with one of these numbers. You can read it with `echo $?` directly after the command.

| Status | Meaning |
| --- | --- |
| 0 | Success. |
| 1 | The task failed, you answered "no" to a confirmation, or a check reported a warning (`ready-fast doctor`, `system-monitor`, `network-info`). |
| 2 | Wrong usage: unknown command, unknown script or invalid option. |

## Environment variables

| Variable | Meaning |
| --- | --- |
| `NO_COLOR` | When set to any non-empty value, output is printed without colours. Colours are also turned off automatically when the output is not a terminal. |
| `READY_FAST_OS_RELEASE` | Path of a file to read instead of `/etc/os-release`. This exists only for the automated tests. Do not use it to get around the operating system check. |

## The installer

`install.sh` lies in the top directory of the project. It is described in [Installation](installation.md).

```bash
sudo ./install.sh
sudo ./install.sh --uninstall
./install.sh --help
```

| Option | Meaning |
| --- | --- |
| (none) | Copy the toolkit to `/opt/ready-fast` and create the link `/usr/local/bin/ready-fast`. |
| `--uninstall` | Remove `/opt/ready-fast` and `/usr/local/bin/ready-fast`. |
| `--help` | Show the help text. |

## Files and directories that ready-fast uses

| Path | Purpose |
| --- | --- |
| `/opt/ready-fast` | The installed toolkit. |
| `/usr/local/bin/ready-fast` | Link to the `ready-fast` command. |
| `/var/backups/ready-fast` | Default directory for backup archives, and for copies of files that scripts replace. |
| `/etc/ssh/sshd_config.d/00-ready-fast.conf` | SSH settings written by `ssh-hardening`. |
| `/etc/apt/sources.list.d/docker.list` | Docker's apt repository, written by `docker-install`. |
| `/etc/apt/keyrings/docker.asc` | Docker's signing key, written by `docker-install`. |
