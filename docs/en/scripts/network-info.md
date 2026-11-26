# network-info

🌐 **English** | [বাংলা](../../bn/scripts/network-info.md)

[← Documentation home](../README.md)

## 1. Introduction

`network-info` prints a short report about the network configuration of your server: its name, IP addresses, default routes, DNS servers and the ports that programs are listening on. It only reads information and never changes anything, so it is safe to run at any time.

Use it when you set up a new server, before you configure a firewall, or when "the network does not work" and you need facts quickly. For help with reading the report, see [Networking](../networking.md).

## 2. What it does

- Shows the hostname of the machine.
- Lists every network interface with its state and IP addresses.
- Shows the default route (the gateway through which the server reaches the internet) for IPv4 and IPv6.
- Lists the DNS servers from `/etc/resolv.conf`.
- Lists the TCP and UDP ports on which programs accept connections.
- With `--public-ip`: asks an external service for the public IP address of the server.
- With `--check`: tests whether DNS names can be resolved and whether an outgoing HTTPS connection works.

## 3. Supported OS

| Distribution | Versions |
| --- | --- |
| Ubuntu | 22.04, 24.04, 26.04 |
| Debian | 12, 13 |

This script does not check the operating system. It should also work on other Linux distributions that have the `iproute2` tools, but it is tested only on the systems in the table. See [Supported OS](../supported-os.md).

## 4. Requirements

- Root permission: **not required**. If you do run it with `sudo`, the list of listening ports also shows the name of the program behind each port.
- The commands `ip` and `ss` from the `iproute2` package. If they are missing, the report says so instead of failing.
- `curl`, only for `--public-ip` and for the HTTPS test of `--check`.
- ready-fast installed (see [Installation](../installation.md)).

## 5. Installation command

Basic report:

```bash
ready-fast run network-info
```

Report that also shows which program uses each port:

```bash
sudo ready-fast run network-info
```

Report with the public IP address and a connectivity test:

```bash
ready-fast run network-info --public-ip --check
```

## 6. Step-by-step explanation

The script runs these read-only commands and prints their output under a heading.

**Hostname**

```bash
hostname
```

**IP addresses**

```bash
ip -brief address show
```

One line per network interface: its name, its state (`UP` or `DOWN`) and its addresses.

**Default routes**

```bash
ip route show default
ip -6 route show default
```

The address after `via` is the gateway. If nothing is printed here, the server has no route to the internet.

**DNS servers**

The script reads the `nameserver` lines of `/etc/resolv.conf`.

**Listening ports**

```bash
ss -tuln
```

`-t` and `-u` select TCP and UDP, `-l` shows only listening sockets and `-n` prints numbers instead of names. As root the script uses `ss -tulnp`, which adds the program name.

**Public IP address** (only with `--public-ip`)

```bash
curl -fsS --max-time 8 https://api.ipify.org
```

**Connectivity check** (only with `--check`)

```bash
getent hosts example.com
curl -fsS --max-time 8 -o /dev/null https://example.com
```

The first line tests DNS resolution. The second tests that the server can open an HTTPS connection to the internet.

## 7. Command options

| Option | Meaning |
| --- | --- |
| `--public-ip` | Also show the public IP address. This sends one request to `https://api.ipify.org`. |
| `--check` | Also test DNS resolution and outgoing HTTPS, using `example.com`. |
| `--help` | Show the help text and exit. |

The exit status is 0 when the report is complete. It is 1 when `--public-ip` or a test of `--check` fails.

## 8. Expected output

Output of `ready-fast run network-info --check` on a small web server. Your names and addresses will be different:

```text

== Hostname ==
web-01

== IP addresses ==
lo               UNKNOWN        127.0.0.1/8 ::1/128
eth0             UP             203.0.113.10/24

== Default routes ==
default via 203.0.113.1 dev eth0

== DNS servers ==
1.1.1.1
8.8.8.8

== Listening ports ==
Netid State  Recv-Q Send-Q Local Address:Port Peer Address:Port
tcp   LISTEN 0      128          0.0.0.0:22        0.0.0.0:*
tcp   LISTEN 0      128             [::]:22           [::]:*

== Connectivity check ==
DNS resolution (example.com): OK
Outbound HTTPS (https://example.com): OK

[OK] Network report complete.
```

When a test fails, the line ends with `FAILED` and the report ends with:

```text
[ERROR] At least one network check failed.
```

## 9. Security considerations

- The script is read-only. It does not change interfaces, routes, DNS settings or firewall rules.
- The report contains IP addresses and open ports. Remove or mask them before you post the output in a public forum or issue.
- `--public-ip` contacts a third-party service (`api.ipify.org`). That service sees the public IP address of your server. Do not use the option if this is not acceptable.
- `--check` contacts `example.com`. No data about your server is sent apart from the connection itself.
- Without these two options the script makes no network connections at all.

## 10. Side effects

None. No files are written and no settings are changed. Only with `--public-ip` or `--check` are short outgoing connections made.

## 11. Rollback instructions

Nothing needs to be rolled back, because the script does not change the system.

## 12. Troubleshooting

| Problem | Cause and solution |
| --- | --- |
| `(the 'ip' command is missing; install the iproute2 package)` | Install the tools with `sudo apt-get install -y iproute2` and run the script again. |
| The DNS server is shown as `127.0.0.53` | The system uses `systemd-resolved`, which answers on this local address and forwards to the real DNS servers. Run `resolvectl status` to see them. |
| `(no default route)` | The server has no gateway and cannot reach the internet. Check the network configuration in the control panel of your provider or in `/etc/netplan/` (Ubuntu) or `/etc/network/interfaces` (Debian). |
| `DNS resolution (example.com): FAILED` | The DNS servers are unreachable or wrong. Check the "DNS servers" section of the report. |
| `Outbound HTTPS (https://example.com): FAILED` although DNS is `OK` | Outgoing connections on port 443 are blocked, usually by a firewall at your provider or by a proxy requirement. |
| `FAILED (could not reach https://api.ipify.org)` | The service is unreachable from your server. The rest of the report is still valid. |
| The port list has no program names | Run the script with `sudo`. |

More general problems are covered in [Troubleshooting](../troubleshooting.md).

## 13. Testing status

| What | How it is tested |
| --- | --- |
| Shell syntax and common mistakes | `shellcheck` in CI on every push |
| Option handling and a basic run | `tests/smoke.sh` in CI, on a GitHub-hosted Ubuntu virtual machine and inside `amd64` containers of Ubuntu 22.04, 24.04, 26.04 and Debian 12, 13 |
| `--public-ip` and `--check` with a working internet connection | Not tested automatically |
| `arm64` | Not tested |
