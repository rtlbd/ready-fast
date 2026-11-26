# Security

🌐 **English** | [বাংলা](../bn/security.md)

[← Documentation home](README.md)

This page explains how ready-fast is built to be safe, what it connects to, and how to secure a new server step by step. It also lists honestly what ready-fast does not do.

## How ready-fast protects you

- **You can read everything.** The toolkit is plain shell script. Nothing is compiled or hidden, and there is no installer that runs code straight from the internet.
- **Preview mode.** Every script that changes something accepts `--dry-run` and then only prints what it would do.
- **Confirmation.** Scripts that change system settings or overwrite files show a summary and wait for your answer. Without a terminal they stop unless `--yes` is given.
- **Operating system check.** Scripts that install software or change system settings stop on systems they were not written for.
- **Lock-out protection.** `ssh-hardening` refuses settings that would leave nobody able to log in, and `firewall-setup` always adds a rule for the SSH port before it turns the firewall on.
- **Configuration is tested before it is used.** `ssh-hardening` runs `sshd -t` and undoes its change automatically if the test fails.
- **A way back.** Every script page has rollback instructions. Files that a script replaces are copied to `/var/backups/ready-fast` first.
- **No tracking.** ready-fast collects no usage data and sends nothing about your server to its authors.

## Internet connections

| Destination | When | Why |
| --- | --- | --- |
| Your apt mirror | `docker-install`, and `firewall-setup` if `ufw` is missing | To install packages. |
| `download.docker.com` | `docker-install` | Docker's signing key and packages. |
| `api.ipify.org` | `network-info`, only with `--public-ip` | To learn the public IP address. This service sees your server's IP address. |
| `example.com` | `network-info`, only with `--check` | To test DNS and outgoing HTTPS. |

All other scripts make no network connections.

## Root permission

Three scripts always need root: `docker-install`, `firewall-setup` and `ssh-hardening`. The backup scripts need it only when the files require it, and the two reporting scripts never need it. Each script page states this in its "Requirements" section.

Good practice: log in as a normal user and put `sudo` in front of a command when root is needed, instead of working as `root` all the time. A mistake made as a normal user usually does much less damage.

## Checklist for a new server

Follow these steps in order. `deploy` is an example user name and `203.0.113.10` an example server address; replace them with your own.

**1. Update the system.** Run on the server:

```bash
sudo apt-get update
sudo apt-get upgrade
```

The first line refreshes the package list; the second installs available updates and asks before it starts.

**2. Create a normal user with administrator rights.** Run on the server:

```bash
sudo adduser deploy
sudo usermod -aG sudo deploy
```

The first line creates the user and asks for a password. The second adds the user to the `sudo` group.

**3. Set up an SSH key.** Run on your own computer, not on the server:

```bash
ssh-keygen -t ed25519
ssh-copy-id deploy@203.0.113.10
```

The first line creates a key pair (press Enter to accept the suggested file name, and choose a passphrase). The second copies the public key to the server.

**4. Test the key login.** Open a new terminal on your own computer:

```bash
ssh deploy@203.0.113.10
```

You should get in without being asked for the server password. Also check that `sudo -v` works for this user. Do not continue until both work.

**5. Save the original configuration.**

```bash
sudo ready-fast run backup-create --source /etc --name etc-original
```

**6. Harden SSH.** This turns off root login and password logins:

```bash
sudo ready-fast run ssh-hardening --root-login no --disable-password-auth
```

Keep your session open and test a new login from another terminal. See [ssh-hardening](scripts/ssh-hardening.md).

**7. Turn on the firewall.** Add `--web` for a web server:

```bash
sudo ready-fast run firewall-setup
```

See [firewall-setup](scripts/firewall-setup.md).

**8. Keep watching.** Check the server regularly and install updates:

```bash
ready-fast run system-monitor
```

See [Monitoring](monitoring.md) and [Backup](backup.md).

## Warnings you should know

- **The `docker` group is root.** Anyone who may run `docker` can take over the server. Add only trusted users.
- **Docker ports bypass UFW.** A container port published with `-p 8080:80` is open to the internet even if the firewall does not list it. Use `-p 127.0.0.1:8080:80` for private services. See [Firewall](firewall.md).
- **Backups are not encrypted.** Archives contain everything that was in the source directories, including secrets. Protect every copy. See [Backup](backup.md).
- **SSH and firewall changes can lock you out.** Always keep one session open and know how to reach the web console of your hosting provider.

## What ready-fast does not do

ready-fast gives a server a sound basic setup. It is not a complete security product:

- It does not install intrusion detection, malware scanners or tools that ban attackers automatically.
- It does not configure automatic security updates.
- It does not change kernel parameters, file permissions or password policies.
- It does not check your applications, containers or websites for vulnerabilities.
- It does not make a server compliant with any security standard.

Security is ongoing work: install updates, review who has access, and test your backups.

## Reporting a security problem in ready-fast

If you find a vulnerability in ready-fast itself, please do not publish the details in a public issue first. Contact the maintainers privately through their GitHub profile at `https://github.com/rtlbd` and allow time for a fix. Ordinary bugs can be reported as described in [Troubleshooting](troubleshooting.md).
