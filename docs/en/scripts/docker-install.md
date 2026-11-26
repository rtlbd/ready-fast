# docker-install

🌐 **English** | [বাংলা](../../bn/scripts/docker-install.md)

[← Documentation home](../README.md)

## 1. Introduction

`docker-install` installs Docker Engine on an Ubuntu or Debian server from Docker's official apt repository. It follows the installation method that Docker itself documents, but adds safety checks, a preview mode and clear messages.

Use it when you have a fresh VPS or dedicated server and want Docker and Docker Compose ready in a few minutes. For a broader guide, see [Docker](../docker.md).

## 2. What it does

- Checks that the operating system and CPU architecture are supported.
- Stops if older or conflicting Docker packages (for example `docker.io`) are installed.
- Installs the helper packages `ca-certificates` and `curl`.
- Downloads Docker's signing key to `/etc/apt/keyrings/docker.asc` and, when `gpg` is available, compares its fingerprint with the one Docker publishes.
- Adds Docker's apt repository in `/etc/apt/sources.list.d/docker.list`.
- Installs `docker-ce`, `docker-ce-cli`, `containerd.io`, `docker-buildx-plugin` and `docker-compose-plugin`.
- Enables and starts the `docker` service.
- Optionally adds one user to the `docker` group.
- Prints the installed Docker and Compose versions.

If Docker Engine (`docker-ce`) is already installed, the script changes nothing and only reports the installed version.

## 3. Supported OS

| Distribution | Versions | Architectures |
| --- | --- | --- |
| Ubuntu | 22.04, 24.04, 26.04 | `amd64`, `arm64` |
| Debian | 12, 13 | `amd64`, `arm64` |

On any other system the script stops before changing anything. See [Supported OS](../supported-os.md).

## 4. Requirements

- Root permission: **required**. Run the command with `sudo`. This is also true for `--dry-run`.
- A working internet connection to your apt mirror and to `download.docker.com`.
- ready-fast installed (see [Installation](../installation.md)).
- About 500 MB of free disk space for the Docker packages.

## 5. Installation command

Preview first. This shows every step and changes nothing:

```bash
sudo ready-fast run docker-install --dry-run
```

Then install:

```bash
sudo ready-fast run docker-install
```

The script lists what it is going to do and asks `Install Docker Engine now? [y/N]:`. Type `y` and press Enter to continue. Any other answer cancels without changes.

To also allow the user `deploy` to use Docker without `sudo`:

```bash
sudo ready-fast run docker-install --user deploy
```

## 6. Step-by-step explanation

The script runs the following commands for you. `<ID>` is `ubuntu` or `debian`, `<arch>` is your CPU architecture and `<codename>` is the release codename of your system (for example `noble`).

**Step 1 — install prerequisites**

```bash
apt-get update
apt-get install -y ca-certificates curl
```

The first line refreshes the package list. The second installs the certificates and the download tool that are needed to fetch Docker's key over HTTPS. The script also passes `DEBIAN_FRONTEND=noninteractive` and a lock timeout of 120 seconds to `apt-get`, so that it never stops to ask a question and waits if another package operation is running; you can see the exact commands with `--dry-run`.

**Step 2 — download Docker's signing key**

```bash
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/<ID>/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
```

The first line creates the key directory. The second downloads the key that apt uses to verify that packages really come from Docker. The third makes the key readable for apt. Before downloading, the script checks that Docker's repository has packages for your release; if not, it stops and adds nothing to apt.

**Step 3 — add Docker's apt repository**

The script writes one line into `/etc/apt/sources.list.d/docker.list`:

```text
deb [arch=<arch> signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/<ID> <codename> stable
```

This tells apt where to find Docker packages and which key to trust for them.

**Step 4 — install Docker**

```bash
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

The package list is refreshed again so that apt sees the new repository, then Docker Engine, its command-line client, the container runtime, Buildx and the Compose plugin are installed.

**Step 5 — enable the service**

```bash
systemctl enable --now docker
```

This starts Docker now and makes it start automatically after every reboot. If systemd is not running (for example inside a container), this step is skipped with a warning.

**Optional — add a user to the docker group** (only with `--user`)

```bash
usermod -aG docker deploy
```

**Verification**

```bash
docker --version
docker compose version
```

## 7. Command options

| Option | Meaning |
| --- | --- |
| `--user <name>` | Also add this existing user to the `docker` group, so that the user can run `docker` without `sudo`. The user must log out and log in again. |
| `--dry-run` | Show what would be done without changing anything. |
| `--yes` | Do not ask for confirmation. Needed when the command runs without a terminal, for example from another script. |
| `--help` | Show the help text and exit. |

## 8. Expected output

A successful installation looks like this. Lines printed by `apt-get` are shortened to `...`, and your version numbers will be different:

```text
[INFO] System: Ubuntu 24.04.5 LTS (amd64)
[INFO] The following will be done:
[INFO]   1. Install the packages ca-certificates and curl
[INFO]   2. Save Docker's signing key to /etc/apt/keyrings/docker.asc
[INFO]   3. Add Docker's apt repository in /etc/apt/sources.list.d/docker.list
[INFO]   4. Install: docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
[INFO]   5. Enable and start the docker service
Install Docker Engine now? [y/N]: y
[INFO] Step 1/5: installing prerequisites
...
[INFO] Step 2/5: downloading Docker's signing key
[OK] Signing key fingerprint verified.
[INFO] Step 3/5: adding Docker's apt repository
[INFO] Step 4/5: installing Docker packages
...
[INFO] Step 5/5: enabling the docker service
[INFO] Verifying the installation
Docker version 29.9.3, build 5457199
Docker Compose version v5.7.1
[OK] The docker service is running.
[OK] Docker Engine is ready. Test it with: sudo docker run --rm hello-world
```

If `gpg` is not installed, the line `[OK] Signing key fingerprint verified.` is replaced by a warning that the fingerprint was not checked.

When Docker is already installed:

```text
[OK] Docker Engine is already installed: Docker version 29.9.3, build 5457199
[INFO] Skipping installation.
[INFO] Verifying the installation
Docker version 29.9.3, build 5457199
Docker Compose version v5.7.1
[OK] The docker service is running.
[OK] Docker Engine is ready. Test it with: sudo docker run --rm hello-world
```

## 9. Security considerations

- **The docker group is equal to root.** Anyone in the `docker` group can start a container that reads or changes any file on the server. Use `--user` only for people you would also trust with `sudo`.
- **Docker can bypass UFW.** A container port published with `-p` (for example `-p 8080:80`) is reachable from the internet even when UFW does not allow it, because Docker writes its own firewall rules. To keep a service private, publish it on localhost only, for example `-p 127.0.0.1:8080:80`. See [Firewall](../firewall.md).
- The script adds a third-party apt repository (`download.docker.com`). Future `apt-get upgrade` runs will install Docker updates from it.
- The signing key is downloaded over HTTPS. Its fingerprint is verified only when `gpg` is installed; otherwise a warning is shown.
- The script does not change the Docker daemon configuration and does not open any firewall port.

## 10. Side effects

- New packages: `ca-certificates`, `curl`, `docker-ce`, `docker-ce-cli`, `containerd.io`, `docker-buildx-plugin`, `docker-compose-plugin` and their dependencies.
- New files: `/etc/apt/keyrings/docker.asc` and `/etc/apt/sources.list.d/docker.list`.
- New services enabled at boot: `docker` and `containerd`.
- Docker creates the network interface `docker0` and its own firewall (iptables/nftables) rules.
- A `docker` group is created. With `--user`, the chosen user becomes a member.
- Images, containers and volumes will later be stored in `/var/lib/docker`.

## 11. Rollback instructions

**Warning:** removing `/var/lib/docker` and `/var/lib/containerd` permanently deletes all images, containers and volumes. Back up anything you need first.

Remove the Docker packages:

```bash
sudo apt-get purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

Remove the repository and the key that the script added:

```bash
sudo rm -f /etc/apt/sources.list.d/docker.list /etc/apt/keyrings/docker.asc
sudo apt-get update
```

Only if you also want to delete all Docker data:

```bash
sudo rm -rf /var/lib/docker /var/lib/containerd
```

If you used `--user`, remove the user from the group again:

```bash
sudo gpasswd -d deploy docker
```

The packages `ca-certificates` and `curl` are left installed because many other programs need them.

## 12. Troubleshooting

| Problem | Cause and solution |
| --- | --- |
| `This script must be run as root.` | Run the command with `sudo`. |
| `Unsupported operating system` | Your system is not in the table in section 3. The script cannot be used there. |
| `Conflicting packages are installed` | An older Docker package such as `docker.io` is present. Remove the listed packages with the `apt-get remove` command shown in the message, then run the script again. |
| `Docker's repository has no packages for '<codename>', or download.docker.com is unreachable.` | Check the internet connection and DNS with `ready-fast run network-info --check`. If the network is fine, Docker does not publish packages for your release yet. |
| `The downloaded key has an unexpected fingerprint` | The downloaded file is not Docker's key. Something between your server and `download.docker.com` (a proxy or a broken mirror) changed it. Do not continue until the network is trusted. |
| `apt-get update` fails with `Conflicting values set for option Signed-By` | Another file in `/etc/apt/sources.list.d/` already defines the Docker repository with a different key path. Remove the duplicate file and run the script again. |
| `Docker is installed but the docker service is not running.` | Read the service log with `journalctl -u docker --no-pager -n 50`. |
| `permission denied while trying to connect to the Docker daemon socket` | Your user is not in the `docker` group, or you have not logged out and in again after being added. Use `sudo docker ...` or log in again. |

More general problems are covered in [Troubleshooting](../troubleshooting.md).

## 13. Testing status

| What | How it is tested |
| --- | --- |
| Shell syntax and common mistakes | `shellcheck` in CI on every push |
| Option handling, unsupported-OS check, root check, `--dry-run` | `tests/smoke.sh` in CI |
| Real installation, second run (already installed), `--user` | `tests/system.sh` in CI, inside `amd64` containers of Ubuntu 22.04, 24.04, 26.04 and Debian 12, 13 |
| Starting the `docker` service through systemd | Not tested automatically (the CI containers have no systemd) |
| `arm64` | Not tested |

Test the script on a non-production server before you rely on it.
