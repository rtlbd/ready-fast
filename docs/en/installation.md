# Installation

🌐 **English** | [বাংলা](../bn/installation.md)

[← Documentation home](README.md)

This page shows how to download ready-fast, install it, check that it works, update it and remove it again. The whole process takes about two minutes.

## Requirements

- A server or computer with a supported system: Ubuntu 22.04, 24.04, 26.04 or Debian 12, 13. See [Supported OS](supported-os.md).
- A user who may use `sudo`, or the `root` user itself. If you are logged in as `root`, leave out the word `sudo` in all commands.
- An internet connection.
- The `git` program, which is installed in step 1.

## Step 1 — Install git

```bash
sudo apt-get update
sudo apt-get install -y git
```

- The first line refreshes the list of available packages.
- The second line installs `git`, the tool that downloads the ready-fast files. `-y` answers "yes" to the installation question.
- Root permission: required (`sudo`).
- Risk: none beyond installing one standard package.

## Step 2 — Download ready-fast

```bash
git clone https://github.com/rtlbd/ready-fast.git
cd ready-fast
```

- The first line downloads the project into a new directory named `ready-fast` inside your current directory.
- The second line enters that directory.
- Root permission: not required.
- Risk: none. Nothing outside the new directory is touched.

## Step 3 — Look before you install

This step is optional but recommended. ready-fast can run directly from the downloaded directory, so you can look at it before anything is installed:

```bash
./ready-fast list
./ready-fast doctor
```

- The first line shows all available scripts.
- The second line checks whether your system is supported.
- Root permission: not required. Both commands only read information.

The scripts are plain text files in the `scripts` directory. You are encouraged to read them before you run them.

## Step 4 — Install

```bash
sudo ./install.sh
```

What this command does:

- It copies the toolkit to `/opt/ready-fast`. If an older copy exists there, it is replaced.
- It creates the link `/usr/local/bin/ready-fast`, so that the command `ready-fast` works from any directory.
- Root permission: required, because both locations belong to the system.
- Risk: changes you made by hand inside `/opt/ready-fast` are lost. Nothing else on the system is changed. If `/usr/local/bin/ready-fast` already exists and is a regular file from another program, the installer stops and changes nothing.

Expected output:

```text
[OK] Installed ready-fast 0.1.0 to /opt/ready-fast
[OK] Command available: /usr/local/bin/ready-fast
[INFO] Next step: ready-fast doctor
```

## Step 5 — Verify

```bash
ready-fast version
ready-fast doctor
```

Expected output of the first command:

```text
ready-fast 0.1.0
```

Expected output of the second command on a fresh server. The "Optional tools" lines depend on what is installed:

```text
ready-fast doctor

  OS:            Ubuntu 24.04.5 LTS (supported)
  Architecture:  amd64 (supported)
  Privileges:    normal user (use sudo for scripts that change the system)
  systemd:       running

  Required tools:
    apt-get      found
    dpkg         found
    tar          found
    sha256sum    found
    awk          found
    grep         found
    sed          found

  Optional tools:
    curl         found
    ip           found
    ss           found
    systemctl    found
    sshd         found
    ufw          not installed
    docker       not installed

[OK] This system is ready for ready-fast.
```

If the last line starts with `[ERROR]`, the lines marked `NOT supported` or `MISSING` tell you what is wrong.

You are ready. Continue with [Quick start](quick-start.md).

## Updating

Go back to the downloaded directory, fetch the newest version and install it again:

```bash
cd ready-fast
git pull
sudo ./install.sh
```

Updating ready-fast does not re-run any script and does not change software that a script installed earlier.

## Uninstalling

```bash
sudo ./install.sh --uninstall
```

Expected output:

```text
[OK] Removed /opt/ready-fast and /usr/local/bin/ready-fast
```

This removes only ready-fast itself. It does **not** undo what the scripts did:

- Software and settings created by scripts (Docker, firewall rules, SSH settings) stay in place. To remove them, follow the "Rollback instructions" section of each script document **before** you uninstall.
- Backups in `/var/backups/ready-fast` are kept.
- The downloaded `ready-fast` directory is kept. Delete it yourself if you no longer need it.

## Why there is no one-line internet installer

Many projects offer a command that downloads a script and immediately runs it as root. ready-fast deliberately does not. With `git clone` you get a copy that you can read first, and you always know exactly which version you installed.

## Troubleshooting

| Problem | Cause and solution |
| --- | --- |
| `git: command not found` | Do step 1 first. |
| `install.sh must be run as root.` | Run the command with `sudo`. |
| `ready-fast: command not found` after installing | `/usr/local/bin` is not in your `PATH`. Use the full path `/usr/local/bin/ready-fast`, or log out and log in again. |
| `exists and is not a symlink` | Another file with this name is in the way. Move it somewhere else, then run the installer again. |
| `is missing. Run install.sh from a complete copy of the repository.` | The download is incomplete. Delete the directory and repeat step 2. |

More help is in [Troubleshooting](troubleshooting.md).
