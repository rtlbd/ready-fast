# Troubleshooting

🌐 **English** | [বাংলা](../bn/troubleshooting.md)

[← Documentation home](README.md)

This page collects the problems that can happen with any ready-fast command. Problems that belong to one script are in the "Troubleshooting" section of that script's page; links are at the end.

## First steps for any problem

1. **Read the last lines of the output.** Lines that start with `[ERROR]` say what went wrong, and usually what to do.
2. **Check the system:**

```bash
ready-fast doctor
```

3. **Run the script in preview mode** to see what it tries to do, without changing anything:

```bash
sudo ready-fast run firewall-setup --dry-run
```

4. **Read the help of the script** to check the spelling of options:

```bash
ready-fast info firewall-setup
```

## Messages from the ready-fast command

| Message | Cause and solution |
| --- | --- |
| `ready-fast: command not found` | ready-fast is not installed, or `/usr/local/bin` is not in your `PATH`. Install it as described in [Installation](installation.md), or use the full path `/usr/local/bin/ready-fast`. |
| `Unknown command` | The word after `ready-fast` is not a command. Run `ready-fast help` to see the valid ones. |
| `Unknown script` | The script name is misspelled. Run `ready-fast list` to see the available scripts. |
| `Unknown option` | The script does not have this option. Check the options with `ready-fast info <script>`. |
| `Option ... requires a value.` | An option such as `--user` was given without the value that must follow it. |

## Permission and confirmation

| Message | Cause and solution |
| --- | --- |
| `This script must be run as root. Re-run it with sudo.` | Put `sudo` in front of the whole command. |
| `sudo: command not found` | You are on a minimal system without `sudo`. Log in as `root` and run the command without `sudo`. |
| `... is not in the sudoers file` | Your user may not use `sudo`. Ask the administrator, or log in as `root` and run `usermod -aG sudo deploy` with your user name, then log in again. |
| `Confirmation is required but no terminal is attached. Re-run with --yes to continue without a prompt.` | The command runs where it cannot ask a question, for example in cron or through a pipe. Add `--yes` if you are sure about the action. |
| `Cancelled. No changes were made.` | You answered the confirmation question with something other than `y`. Run the command again if that was a mistake. |

## Operating system

| Message | Cause and solution |
| --- | --- |
| `Unsupported operating system` | The script supports only the systems listed in [Supported OS](supported-os.md). The check cannot be switched off. |
| `Unsupported CPU architecture` | `docker-install` supports only `amd64` and `arm64`. |
| `VERSION_CODENAME is missing from the os-release file` | The file `/etc/os-release` is incomplete, which happens on unusual or modified systems. ready-fast cannot be used there. |

## Installing packages (apt)

`docker-install` and `firewall-setup` install packages with `apt-get`. Most failures in these scripts come from apt itself.

| Message | Cause and solution |
| --- | --- |
| `Could not get lock /var/lib/dpkg/lock-frontend` | Another package operation is running, often the automatic updates right after boot. ready-fast waits up to 120 seconds. If it still fails, wait a few minutes and run the script again. |
| `dpkg was interrupted, you must manually run 'sudo dpkg --configure -a'` | An earlier installation was interrupted. Run exactly the command shown in the message, then run the script again. |
| `Unable to locate package` | The package list is outdated or the software sources are incomplete. Run `sudo apt-get update` and look for errors in its output. |
| `Temporary failure resolving` or `Could not resolve` | DNS does not work. See the next section. |
| `Release file ... is not valid yet` | The server clock is wrong. Check it with `date` and turn on time synchronisation with `sudo timedatectl set-ntp true`. |

## Network

Start with the network report and its built-in tests:

```bash
ready-fast run network-info --check
```

- `(no default route)`: the server has no gateway. Check the network settings in the control panel of your provider.
- `DNS resolution (example.com): FAILED`: the DNS servers listed in the report do not answer.
- DNS is `OK` but HTTPS fails: outgoing connections are blocked by a firewall outside the server, or the server must use a proxy.

More explanation is in [Networking](networking.md).

## Locked out of the server

If you can no longer log in with SSH after changing SSH or firewall settings:

1. Do not close any SSH session that is still open. Use it to undo the change.
2. Otherwise open the web console (often called VNC, KVM or serial console) in the control panel of your hosting provider and log in there.
3. Undo the last change:

```bash
sudo ready-fast run ssh-hardening --rollback
sudo ufw disable
```

The first line removes the SSH settings written by ready-fast. The second line turns the firewall off; its rules are kept. Then find the cause before you try again.

## A script stopped in the middle

The scripts are written so that they can be run again safely:

- `docker-install` skips the installation when Docker is already installed. If it stopped earlier, run it again; apt continues where it stopped.
- `firewall-setup` does not add a rule a second time when it already exists.
- `ssh-hardening` writes its file again from the beginning.
- `backup-create` deletes an incomplete archive when it fails.

## Problems with one script

| Script | Troubleshooting section |
| --- | --- |
| docker-install | [docker-install](scripts/docker-install.md) |
| firewall-setup | [firewall-setup](scripts/firewall-setup.md) |
| ssh-hardening | [ssh-hardening](scripts/ssh-hardening.md) |
| network-info | [network-info](scripts/network-info.md) |
| system-monitor | [system-monitor](scripts/system-monitor.md) |
| backup-create | [backup-create](scripts/backup-create.md) |
| backup-restore | [backup-restore](scripts/backup-restore.md) |

## Reporting a problem

If you cannot solve the problem, open an issue at `https://github.com/rtlbd/ready-fast/issues`. Include the output of these three commands:

```bash
ready-fast version
ready-fast doctor
cat /etc/os-release
```

Also include the exact command you ran and its complete output. Before you post, remove passwords, keys and, if you prefer, IP addresses. You may write the issue in English or in Bengali.
