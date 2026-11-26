# ssh-hardening

🌐 **English** | [বাংলা](../../bn/scripts/ssh-hardening.md)

[← Documentation home](../README.md)

## 1. Introduction

`ssh-hardening` makes the OpenSSH server (the program that accepts your SSH logins) safer. Every server on the internet is constantly probed by bots that try to guess passwords, so tightening SSH is one of the first things to do on a new server.

The script never edits the main configuration file `/etc/ssh/sshd_config` and never changes the SSH port. It writes its settings into one separate file, so everything can be undone with a single command. For the wider picture, see [Security](../security.md).

## 2. What it does

- Checks that the OpenSSH server is installed and that `/etc/ssh/sshd_config` loads files from `/etc/ssh/sshd_config.d/`.
- Writes the file `/etc/ssh/sshd_config.d/00-ready-fast.conf` with the settings listed below.
- Refuses options that would leave nobody able to log in.
- Tests the new configuration with `sshd -t`. If the test fails, the change is undone automatically.
- Reloads the SSH service so that the settings apply to new connections.
- Shows the settings that are now in effect.

Settings that are always applied:

| Setting | Effect |
| --- | --- |
| `PermitEmptyPasswords no` | Accounts with an empty password cannot log in. |
| `MaxAuthTries 4` | A connection is closed after 4 failed login attempts. |
| `LoginGraceTime 30` | A connection that has not logged in within 30 seconds is closed. |
| `X11Forwarding no` | Graphical forwarding, which servers rarely need, is turned off. |
| `ClientAliveInterval 300` and `ClientAliveCountMax 2` | A client that has stopped responding is disconnected after about 10 minutes. |

Settings that are applied only when you ask for them:

| Option | Setting written | Effect |
| --- | --- | --- |
| `--root-login <mode>` | `PermitRootLogin <mode>` | Controls whether `root` may log in over SSH. |
| `--disable-password-auth` | `PasswordAuthentication no` and `KbdInteractiveAuthentication no` | Only SSH keys are accepted; passwords are refused. |

## 3. Supported OS

| Distribution | Versions |
| --- | --- |
| Ubuntu | 22.04, 24.04, 26.04 |
| Debian | 12, 13 |

On any other system the script stops before changing anything. See [Supported OS](../supported-os.md).

## 4. Requirements

- Root permission: **required**. Run the command with `sudo`. This is also true for `--dry-run`.
- The OpenSSH server (`openssh-server` package) must be installed.
- ready-fast installed (see [Installation](../installation.md)).
- For `--disable-password-auth`: your SSH public key must already be in `~/.ssh/authorized_keys` on the server.
- Strongly recommended: keep your current SSH session open while you test, and have the web console of your hosting provider available.

## 5. Installation command

Preview first. This shows the file that would be written and changes nothing:

```bash
sudo ready-fast run ssh-hardening --dry-run
```

Apply the basic settings. These do not change who can log in:

```bash
sudo ready-fast run ssh-hardening
```

Allow `root` to log in with an SSH key only, never with a password:

```bash
sudo ready-fast run ssh-hardening --root-login prohibit-password
```

Strictest setup: no root login and no password logins at all. Do this only after you have confirmed that a normal user can log in with an SSH key and can use `sudo`:

```bash
sudo ready-fast run ssh-hardening --root-login no --disable-password-auth
```

Each run replaces the file completely. Options that you leave out are removed from it again, so always pass every option you want to keep.

## 6. Step-by-step explanation

**Step 1 — checks.** The script verifies root permission, the operating system, that `sshd` exists and that `/etc/ssh/sshd_config` contains the line `Include /etc/ssh/sshd_config.d/*.conf`. Without that line a separate file would have no effect, so the script stops.

**Step 2 — lock-out protection.** The script looks at the accounts on the server (`root` and regular users with UID 1000 or higher that have a login shell):

- `--root-login no` is refused when there is no regular user who could log in instead.
- `--root-login prohibit-password` is refused when `root` has no SSH key and there is no regular user.
- `--disable-password-auth` is refused when no account that is allowed to log in has an SSH key in `~/.ssh/authorized_keys`.

**Step 3 — confirmation.** The exact content of the new file is shown and you are asked `Apply these SSH settings? [y/N]:`.

**Step 4 — write the file.** If `/etc/ssh/sshd_config.d/00-ready-fast.conf` already exists, a copy is saved in `/var/backups/ready-fast/ssh-hardening/`. Then the new file is written with permission `0600`. The name starts with `00-` because OpenSSH uses the first value it reads for each setting; this makes the ready-fast file win over other files in the directory, such as `50-cloud-init.conf`.

**Step 5 — test the configuration.**

```bash
sshd -t
```

This asks OpenSSH to check the whole configuration without applying it. If it reports an error, the script restores the previous state and stops; the running SSH service is not touched.

**Step 6 — reload the service.**

```bash
systemctl reload ssh
```

A reload makes the SSH service read the new configuration. Existing sessions, including yours, stay connected.

**Step 7 — show the result.**

```bash
sshd -T
```

The script filters this output and prints only the settings it manages.

## 7. Command options

| Option | Meaning |
| --- | --- |
| `--root-login <mode>` | Set `PermitRootLogin`. `<mode>` is `yes` (root may log in with password or key), `prohibit-password` (root may log in with an SSH key only) or `no` (root cannot log in over SSH). Without this option the current setting is left unchanged. |
| `--disable-password-auth` | Turn off password logins for everyone. Only SSH keys work afterwards. |
| `--rollback` | Remove the file written by this script and reload the SSH service. Cannot be combined with the two options above. |
| `--dry-run` | Show what would be done without changing anything. |
| `--yes` | Do not ask for confirmation. |
| `--help` | Show the help text and exit. |

## 8. Expected output

Output of `sudo ready-fast run ssh-hardening`:

```text
[INFO] System: Ubuntu 24.04.5 LTS
[INFO] This file will be written: /etc/ssh/sshd_config.d/00-ready-fast.conf
    # Managed by ready-fast (ssh-hardening). Do not edit by hand.
    # Remove with: ready-fast run ssh-hardening --rollback
    PermitEmptyPasswords no
    MaxAuthTries 4
    LoginGraceTime 30
    X11Forwarding no
    ClientAliveInterval 300
    ClientAliveCountMax 2
Apply these SSH settings? [y/N]: y
[OK] sshd accepted the new configuration.
[OK] The SSH service was reloaded.
[INFO] Settings now in effect:
    logingracetime 30
    maxauthtries 4
    clientaliveinterval 300
    clientalivecountmax 2
    permitrootlogin without-password
    passwordauthentication yes
    kbdinteractiveauthentication no
    x11forwarding no
    permitemptypasswords no
[OK] Done. Keep this session open and test a new SSH login from another terminal.
```

The values of `permitrootlogin` and `passwordauthentication` depend on your server and on the options you used. OpenSSH prints `without-password` for the mode `prohibit-password`; both names mean the same.

When a dangerous option is refused:

```text
[ERROR] Refusing --disable-password-auth: no account that is allowed to log in has an SSH key in ~/.ssh/authorized_keys. Add your public key first. Nothing was changed.
```

## 9. Security considerations

- **Risk of locking yourself out.** `--disable-password-auth` and `--root-login` change who can log in. Keep your current session open, open a second terminal, and confirm that a new login works before you close anything.
- The lock-out protection is a safety net, not a guarantee. It checks that a key file exists; it cannot know whether you still have the matching private key, or whether your regular user is allowed to use `sudo`.
- Only plain key lines in `authorized_keys` are counted. A line that starts with options such as `command="..."` is ignored, because such keys are often restricted and cannot open a normal shell.
- The basic settings do not stop password guessing by themselves. For real protection use SSH keys together with `--disable-password-auth`, and limit access with [firewall-setup](firewall-setup.md).
- The script does not change the SSH port, the host keys, the allowed ciphers or the users and groups that may log in.

## 10. Side effects

- New file: `/etc/ssh/sshd_config.d/00-ready-fast.conf`.
- When the file is replaced or removed, the old version is copied to `/var/backups/ready-fast/ssh-hardening/`.
- The SSH service is reloaded. Open sessions are not interrupted.
- Settings with the same name in other files of `/etc/ssh/sshd_config.d/` or in `/etc/ssh/sshd_config` no longer have an effect, because the ready-fast file is read first.
- Unresponsive SSH clients are disconnected after about 10 minutes; logins must be completed within 30 seconds.

## 11. Rollback instructions

Remove the ready-fast settings and reload SSH:

```bash
sudo ready-fast run ssh-hardening --rollback
```

The script saves a copy of the file in `/var/backups/ready-fast/ssh-hardening/`, deletes it, checks the configuration with `sshd -t` and reloads the SSH service. Your server then uses exactly the settings it had before ready-fast.

If the `ready-fast` command is not available, do the same by hand:

```bash
sudo rm -f /etc/ssh/sshd_config.d/00-ready-fast.conf
sudo sshd -t
sudo systemctl reload ssh
```

If you cannot log in over SSH any more, use the web console of your hosting provider to log in and run the commands above there.

## 12. Troubleshooting

| Problem | Cause and solution |
| --- | --- |
| `This script must be run as root.` | Run the command with `sudo`. |
| `The OpenSSH server (sshd) is not installed.` | Install it with `sudo apt-get install -y openssh-server`, or skip this script if the machine has no SSH access. |
| `/etc/ssh/sshd_config does not include /etc/ssh/sshd_config.d/*.conf` | The main configuration file was changed and no longer loads separate files. Add the line `Include /etc/ssh/sshd_config.d/*.conf` at the top of `/etc/ssh/sshd_config`, then run the script again. |
| `Refusing --disable-password-auth` | No usable SSH key was found. From your own computer run `ssh-copy-id deploy@203.0.113.10` (with your user name and server address), confirm that key login works, then run the script again. |
| `Refusing --root-login no` | There is no regular user. Create one with `sudo adduser deploy`, give it administrator rights with `sudo usermod -aG sudo deploy`, test the login, then run the script again. |
| `sshd rejected the new configuration, so the change was undone.` | The error printed above this message names the file and line that OpenSSH does not accept. It is usually an older mistake in `/etc/ssh/sshd_config`. Fix it and run the script again. |
| `Too many authentication failures` when logging in | Your SSH client offers more than 4 keys. Tell it which key to use: `ssh -o IdentitiesOnly=yes -i ~/.ssh/id_ed25519 deploy@203.0.113.10`. |
| `The ssh service is not running under systemd, so it was not reloaded.` | The file was written, but the service could not be reloaded (for example inside a container). The settings apply the next time the SSH server starts. |

More general problems are covered in [Troubleshooting](../troubleshooting.md).

## 13. Testing status

| What | How it is tested |
| --- | --- |
| Shell syntax and common mistakes | `shellcheck` in CI on every push |
| Option validation, unsupported-OS check | `tests/smoke.sh` in CI |
| Apply, settings in effect, refusal of unsafe options, `--disable-password-auth` with `--root-login no`, backup of the previous file, `--rollback` | `tests/system.sh` in CI, inside `amd64` containers of Ubuntu 22.04, 24.04, 26.04 and Debian 12, 13 |
| Reload of a running SSH service through systemd | `tests/system.sh` in CI on GitHub-hosted Ubuntu 22.04 and 24.04 virtual machines |
| A real SSH login after hardening | Not tested automatically |
| `arm64` | Not tested |

Test the script on a non-production server before you rely on it.
