# Supported OS

🌐 **English** | [বাংলা](../bn/supported-os.md)

[← Documentation home](README.md)

ready-fast is written for Ubuntu and Debian servers. This page lists the exact versions, explains what "supported" means for each script, and shows how to check your own system.

## Supported systems

| Distribution | Version | Codename | Architectures |
| --- | --- | --- | --- |
| Ubuntu | 22.04 LTS | `jammy` | `amd64`, `arm64` |
| Ubuntu | 24.04 LTS | `noble` | `amd64`, `arm64` |
| Ubuntu | 26.04 LTS | `resolute` | `amd64`, `arm64` |
| Debian | 12 | `bookworm` | `amd64`, `arm64` |
| Debian | 13 | `trixie` | `amd64`, `arm64` |

`amd64` is the normal 64-bit Intel or AMD processor that most VPS and dedicated servers use. `arm64` is the 64-bit ARM processor found in some cloud servers.

## How to check your system

Show the name and version of your operating system:

```bash
cat /etc/os-release
```

Look at the lines `ID`, `VERSION_ID` and `VERSION_CODENAME`. ready-fast reads exactly these three values.

Show your processor architecture:

```bash
dpkg --print-architecture
```

Or let ready-fast check everything at once:

```bash
ready-fast doctor
```

The lines `OS:` and `Architecture:` end with `(supported)` or `(NOT supported)`.

## What "supported" means for each script

Scripts that install software or change system settings refuse to run on a system that is not in the table above. They stop with the message `Unsupported operating system` before anything is changed. Scripts that only read information, or that only work with files you name, do not check the operating system.

| Script | Checks the OS | Checks the architecture | Needs systemd |
| --- | --- | --- | --- |
| [docker-install](scripts/docker-install.md) | Yes | Yes | To start the service |
| [firewall-setup](scripts/firewall-setup.md) | Yes | No | No |
| [ssh-hardening](scripts/ssh-hardening.md) | Yes | No | To reload the service |
| [network-info](scripts/network-info.md) | No | No | No |
| [system-monitor](scripts/system-monitor.md) | No | No | Only for the list of failed services |
| [backup-create](scripts/backup-create.md) | No | No | No |
| [backup-restore](scripts/backup-restore.md) | No | No | No |

The scripts that do not check the operating system will usually work on other Linux distributions too, but they are tested only on the systems in the table.

## Environments with limits

- **Containers without systemd** (for example a Docker container): scripts run, but services cannot be started or reloaded automatically. The scripts print a warning and continue.
- **Container-based VPS products (OpenVZ, LXC):** the kernel is shared with the host. UFW often cannot be enabled there, and Docker may not run. Ask your provider.
- **Desktop editions:** Ubuntu Desktop and Debian with a desktop report the same version values as the server editions, so the scripts run. They are not tested separately.
- **WSL (Windows Subsystem for Linux):** not tested.

## What is not supported

- **Older releases** such as Ubuntu 20.04 and Debian 11. They have reached the end of their standard support period, and new servers should not be built on them.
- **Distributions based on Ubuntu or Debian that use their own identity**, such as Linux Mint or Kali Linux. Their `ID` value is different, so the check refuses them.
- **Red Hat family** (RHEL, Rocky Linux, AlmaLinux, CentOS, Fedora). These use the `dnf` package manager instead of `apt-get`.
- **Other distributions** such as Arch Linux, Alpine Linux and openSUSE.

The check cannot be switched off. This is deliberate: a script that edits system configuration on a system it does not know can do real damage.

## How support is tested

Every push to the repository runs these automated tests in GitHub Actions:

| Test | Where it runs | What it covers |
| --- | --- | --- |
| `shellcheck` | GitHub-hosted Ubuntu virtual machine | Static analysis of every shell file. |
| `tests/smoke.sh` | The same virtual machine, and inside containers of every supported system | Commands, options, the checks for root and operating system, read-only scripts, and a complete backup and restore. |
| `tests/system.sh` in containers | `amd64` containers of Ubuntu 22.04, 24.04, 26.04 and Debian 12, 13 | Installing ready-fast, a real Docker installation, and applying and rolling back the SSH settings. |
| `tests/system.sh` on virtual machines | GitHub-hosted Ubuntu 22.04 and 24.04 virtual machines with systemd | Reloading the SSH service and really enabling the firewall. |

Known gaps: `arm64` is not tested automatically, and the firewall is enabled for real only on Ubuntu 22.04 and 24.04. Each script page has a "Testing status" section with the details.

## Asking for another system

If you need a system that is not listed, open an issue at `https://github.com/rtlbd/ready-fast/issues` and include the output of `cat /etc/os-release`.
