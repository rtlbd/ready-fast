# Quick start

🌐 **English** | [বাংলা](../bn/quick-start.md)

[← Documentation home](README.md)

This page takes you from an empty server to your first ready-fast commands in about ten minutes. You do not need Linux experience; every command is explained.

## Before you start

- You need a server with Ubuntu 22.04, 24.04, 26.04 or Debian 12, 13, and a user who may use `sudo`.
- If this is a real server with important data, read the page of a script before you run it.
- Keep one rule in mind from the beginning: **preview first, then run.**

## Step 1 — Install ready-fast

```bash
sudo apt-get update
sudo apt-get install -y git
git clone https://github.com/rtlbd/ready-fast.git
cd ready-fast
sudo ./install.sh
```

These lines install `git`, download ready-fast and install the `ready-fast` command. Each line is explained in [Installation](installation.md).

## Step 2 — Check your system

```bash
ready-fast doctor
```

This command only reads information and needs no root permission. It tells you whether your operating system is supported and which tools are present. The last line should be:

```text
[OK] This system is ready for ready-fast.
```

## Step 3 — See what is available

```bash
ready-fast list
```

Expected output:

```text
SCRIPT             ROOT       DESCRIPTION
backup-create      depends    Create a compressed tar.gz backup of files or directories, with a SHA-256 checksum
backup-restore     depends    Verify, list or extract a backup archive created by backup-create
docker-install     yes        Install Docker Engine and the Compose plugin from Docker's official apt repository
firewall-setup     yes        Configure the UFW firewall: deny incoming traffic, keep SSH open, allow chosen ports
network-info       no         Show network interfaces, routes, DNS servers and listening ports (read-only)
ssh-hardening      yes        Apply safer OpenSSH server settings through a drop-in file, with built-in rollback
system-monitor     no         Report CPU load, memory, disk usage and failed services, with warning thresholds (read-only)
```

The `ROOT` column tells you whether a script needs `sudo`: `yes` means always, `no` means never, and `depends` means only when the files you work with need it.

To read the help text of one script:

```bash
ready-fast info docker-install
```

## Step 4 — Try the read-only scripts

These two scripts cannot break anything, because they only read information. They are the best way to get used to the tool.

```bash
ready-fast run system-monitor
ready-fast run network-info
```

The first prints a health report (CPU load, memory, disk). The second prints the network configuration (IP addresses, DNS servers, open ports). See [system-monitor](scripts/system-monitor.md) and [network-info](scripts/network-info.md).

## Step 5 — Preview, then run a script that changes the system

Installing Docker is a good first example. Start with the preview:

```bash
sudo ready-fast run docker-install --dry-run
```

With `--dry-run` the script prints every command it would run, each marked with `[DRY-RUN]`, and changes nothing. Read the list. When you are happy with it, run the script for real:

```bash
sudo ready-fast run docker-install
```

The script shows a summary and asks for confirmation. Type `y` and press Enter. When it has finished, test Docker:

```bash
sudo docker run --rm hello-world
```

This downloads a tiny test image, runs it once and removes the container again. A message that starts with `Hello from Docker!` means everything works. Details are in [docker-install](scripts/docker-install.md).

## A sensible order for a new server

If you are setting up a fresh server, this order keeps you safe at every step. Always run the `--dry-run` preview of a script first.

| Order | Goal | Command |
| --- | --- | --- |
| 1 | Save the original configuration | `sudo ready-fast run backup-create --source /etc --name etc-original` |
| 2 | Make SSH safer | `sudo ready-fast run ssh-hardening` |
| 3 | Turn on the firewall (here for a web server) | `sudo ready-fast run firewall-setup --web` |
| 4 | Install Docker, if you need it | `sudo ready-fast run docker-install` |
| 5 | Check the health of the server | `ready-fast run system-monitor` |

After steps 2 and 3, keep your current SSH session open and confirm from a second terminal that you can still log in.

## Three rules to remember

1. **Preview first.** Use `--dry-run` before every script that changes something.
2. **Never close your only session.** After changing SSH or firewall settings, test a new login before you log out.
3. **Know the way back.** Every script page has a "Rollback instructions" section. Read it before you need it.

## Where to go next

- All commands and options: [Command reference](commands.md)
- Securing a new server: [Security](security.md)
- Something does not work: [Troubleshooting](troubleshooting.md)
