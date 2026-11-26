# firewall-setup

🌐 **English** | [বাংলা](../../bn/scripts/firewall-setup.md)

[← Documentation home](../README.md)

## 1. Introduction

`firewall-setup` turns on a basic firewall with UFW (Uncomplicated Firewall), the standard firewall tool on Ubuntu and Debian. After it has run, the server accepts new incoming connections only on the ports you have chosen, and SSH stays open so that you do not lose access.

A firewall decides which network connections are allowed to reach your server. For background and more examples, see [Firewall](../firewall.md).

## 2. What it does

- Checks that the operating system is supported and that `firewalld` (another firewall manager) is not active.
- Finds the port that your SSH server uses, so that it can be kept open.
- Installs the `ufw` package if it is missing.
- Sets the default policy: block all incoming connections, allow all outgoing connections.
- Allows incoming connections to the SSH port, and to any ports you add with `--web` or `--allow`.
- Enables the firewall immediately and at every boot.
- Shows the final firewall status.

UFW rules that already exist are kept. The script only adds rules; it never deletes one.

## 3. Supported OS

| Distribution | Versions |
| --- | --- |
| Ubuntu | 22.04, 24.04, 26.04 |
| Debian | 12, 13 |

On any other system the script stops before changing anything. UFW needs kernel firewall support; on some container-based VPS products (OpenVZ, LXC) the firewall cannot be enabled. See [Supported OS](../supported-os.md).

## 4. Requirements

- Root permission: **required**. Run the command with `sudo`. This is also true for `--dry-run`.
- An internet connection to your apt mirror, if `ufw` is not installed yet.
- ready-fast installed (see [Installation](../installation.md)).
- Recommended: a second way into the server (the web console of your hosting provider), in case you lock yourself out.

## 5. Installation command

Preview first. This shows the rules that would be added and changes nothing:

```bash
sudo ready-fast run firewall-setup --dry-run
```

Basic firewall that only keeps SSH open:

```bash
sudo ready-fast run firewall-setup
```

Web server (SSH, HTTP and HTTPS):

```bash
sudo ready-fast run firewall-setup --web
```

Web server plus a WireGuard VPN on UDP port 51820:

```bash
sudo ready-fast run firewall-setup --web --allow 51820/udp
```

The script lists the rules and asks `Apply these firewall settings? [y/N]:`. Check that the SSH port in the list is correct before you answer `y`.

## 6. Step-by-step explanation

**Step 1 — detect the SSH port**

The script reads the port of your current SSH connection (when available) and the ports configured in the SSH server with `sshd -T`. Every port found is allowed. If nothing can be detected, port 22 is used. With `--ssh-port` you choose the port yourself; the script then warns you if the SSH server seems to use a different one.

**Step 2 — install UFW** (only if it is missing)

```bash
apt-get update
apt-get install -y ufw
```

The first line refreshes the package list and the second installs UFW. The script also passes `DEBIAN_FRONTEND=noninteractive` and a lock timeout of 120 seconds to `apt-get`, so that it never stops to ask a question and waits if another package operation is running; you can see the exact commands with `--dry-run`.

**Step 3 — set the default policy**

```bash
ufw default deny incoming
ufw default allow outgoing
```

The first line blocks every new connection from outside unless a rule allows it. The second line lets the server itself connect out freely, for example to download updates.

**Step 4 — add the allow rules**

```bash
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
```

One `ufw allow` command is run for the SSH port and for each port you asked for. In this example `--web` was used, which adds 80/tcp (HTTP) and 443/tcp (HTTPS).

**Step 5 — enable the firewall**

```bash
ufw --force enable
```

This activates the rules now and after every reboot. The `ufw --force enable` form only skips UFW's own "are you sure?" question, because the script has already asked you.

**Step 6 — show the result**

```bash
ufw status verbose
```

## 7. Command options

| Option | Meaning |
| --- | --- |
| `--ssh-port <port>` | The SSH port to keep open. Without this option the port is detected automatically; if that fails, 22 is used. |
| `--web` | Also allow HTTP (80/tcp) and HTTPS (443/tcp). |
| `--allow <port[/proto]>` | Also allow this port. `proto` is `tcp` or `udp`; without it both protocols are allowed. Can be given several times. |
| `--dry-run` | Show what would be done without changing anything. |
| `--yes` | Do not ask for confirmation. |
| `--help` | Show the help text and exit. |

## 8. Expected output

Output of `sudo ready-fast run firewall-setup --dry-run --web --allow 51820/udp` on a server where SSH uses port 22:

```text
[INFO] System: Ubuntu 24.04.5 LTS
[INFO] The following will be done:
[INFO]   1. Install the package ufw (if missing)
[INFO]   2. Default policy: deny incoming, allow outgoing
[INFO]   3. Allow incoming: 22/tcp 80/tcp 443/tcp 51820/udp
[INFO]   4. Enable the firewall now and at every boot
[WARN] If the SSH port above is wrong, you can lock yourself out of this server.
[INFO] Step 1/4: installing ufw
[INFO] ufw is already installed.
[INFO] Step 2/4: setting the default policy
[DRY-RUN] ufw default deny incoming
[DRY-RUN] ufw default allow outgoing
[INFO] Step 3/4: adding allow rules
[DRY-RUN] ufw allow 22/tcp
[DRY-RUN] ufw allow 80/tcp
[DRY-RUN] ufw allow 443/tcp
[DRY-RUN] ufw allow 51820/udp
[INFO] Step 4/4: enabling the firewall
[DRY-RUN] ufw --force enable
[OK] Dry run finished. Nothing was changed.
```

A real run prints the same `[INFO]` lines, the messages of each `ufw` command instead of the `[DRY-RUN]` lines, and ends with the firewall status:

```text
Status: active
Logging: on (low)
Default: deny (incoming), allow (outgoing), disabled (routed)
New profiles: skip

To                         Action      From
--                         ------      ----
22/tcp                     ALLOW IN    Anywhere
80/tcp                     ALLOW IN    Anywhere
443/tcp                    ALLOW IN    Anywhere
51820/udp                  ALLOW IN    Anywhere
22/tcp (v6)                ALLOW IN    Anywhere (v6)
80/tcp (v6)                ALLOW IN    Anywhere (v6)
443/tcp (v6)               ALLOW IN    Anywhere (v6)
51820/udp (v6)             ALLOW IN    Anywhere (v6)

[OK] The firewall is active. Keep this session open and confirm that a new SSH login still works.
```

## 9. Security considerations

- **Risk of locking yourself out.** If the SSH port in the rule list is wrong, new SSH logins will be blocked. Always read the list before confirming, keep your current session open, and test a new login from a second terminal.
- **Docker can bypass UFW.** Ports published by Docker containers with `-p` are reachable even when UFW has no rule for them. Publish private services on `127.0.0.1` only. See [Docker](../docker.md).
- Outgoing connections are not restricted. The firewall does not stop a compromised program on the server from connecting out.
- The SSH port is opened for every address and is not rate-limited. To slow down password guessing, you can replace the rule yourself with `sudo ufw limit 22/tcp`, and you should harden SSH with [ssh-hardening](ssh-hardening.md).
- `--allow 8080` without a protocol opens the port for both TCP and UDP. Add `/tcp` or `/udp` to open only what you need.
- The firewall applies to IPv4 and IPv6 (UFW's default).

## 10. Side effects

- The `ufw` package is installed if it was missing.
- UFW's default policy is changed to "deny incoming, allow outgoing", even if you had set something else before.
- New allow rules are added. Existing rules stay as they are.
- The firewall is enabled now and at every boot.
- Incoming connections to ports without an allow rule stop working immediately. Connections that are already open, such as your SSH session, continue.

## 11. Rollback instructions

Turn the firewall off. All rules are kept, but no longer applied:

```bash
sudo ufw disable
```

Remove one rule that the script added, for example HTTP:

```bash
sudo ufw delete allow 80/tcp
```

Delete **all** UFW rules and turn the firewall off. This also removes rules that you created yourself:

```bash
sudo ufw --force reset
```

Remove UFW completely:

```bash
sudo apt-get purge -y ufw
```

## 12. Troubleshooting

| Problem | Cause and solution |
| --- | --- |
| `This script must be run as root.` | Run the command with `sudo`. |
| `firewalld is active on this system.` | Two firewall managers must not run together. Either keep using firewalld, or stop it with `sudo systemctl disable --now firewalld` and run the script again. |
| `Could not detect the SSH port; assuming 22.` | The SSH server is not installed or its configuration could not be read. If SSH uses another port, pass it with `--ssh-port`. |
| I am locked out of SSH | Log in through the web console (VNC or serial console) of your hosting provider and run `sudo ufw allow 22/tcp` with your real SSH port, or `sudo ufw disable`. |
| My website is not reachable after the firewall was enabled | Ports 80 and 443 are not allowed. Run `sudo ufw allow 80/tcp` and `sudo ufw allow 443/tcp`, or run the script again with `--web`. |
| `ufw --force enable` fails with an `iptables` or `ufw-init` error | The kernel does not offer the firewall features UFW needs. This is common on OpenVZ or LXC based VPS products; ask your provider, or use the firewall in the provider's control panel instead. |
| A Docker container port is open although UFW does not list it | This is expected Docker behaviour; see section 9. |

More general problems are covered in [Troubleshooting](../troubleshooting.md).

## 13. Testing status

| What | How it is tested |
| --- | --- |
| Shell syntax and common mistakes | `shellcheck` in CI on every push |
| Option validation, unsupported-OS check, root check, `--dry-run` output | `tests/smoke.sh` in CI |
| Real run: rules added, firewall active, then `ufw disable` | `tests/system.sh` in CI on GitHub-hosted Ubuntu 22.04 and 24.04 virtual machines |
| Real run on Ubuntu 26.04 and Debian 12, 13 | Not tested automatically; only `--dry-run` runs there (the CI containers cannot enable a firewall) |
| Custom SSH port detection on a live SSH server | Not tested automatically |

Test the script on a non-production server before you rely on it.
