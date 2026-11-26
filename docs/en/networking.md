# Networking

🌐 **English** | [বাংলা](../bn/networking.md)

[← Documentation home](README.md)

Before you can secure or repair a server, you need to know how it is connected: which addresses it has, how it reaches the internet, and which programs are waiting for connections. This guide shows how to get that information with ready-fast and how to read it.

ready-fast only reports on the network. It never changes IP addresses, routes or DNS settings. The script behind this guide is documented in [network-info](scripts/network-info.md).

## Get the report

```bash
ready-fast run network-info
```

- Root permission: not required.
- Risk: none. The script only reads information.

With `sudo`, the port list also shows which program owns each port:

```bash
sudo ready-fast run network-info
```

To include the public IP address and a connectivity test:

```bash
ready-fast run network-info --public-ip --check
```

`--public-ip` asks the external service `api.ipify.org`, and `--check` connects to `example.com`. Without these options no connection leaves your server.

## Reading the report

### Hostname

The name the server gives itself. It is only a label; changing it does not change how the server is reached.

### IP addresses

Each line is one network interface:

```text
lo               UNKNOWN        127.0.0.1/8 ::1/128
eth0             UP             203.0.113.10/24
docker0          DOWN           172.17.0.1/16
```

- `lo` is the loopback interface. The address `127.0.0.1` always means "this machine itself".
- `eth0` (on many servers `ens3`, `enp1s0` or similar) is the real network card. `UP` means it is connected.
- `docker0` appears when Docker is installed. It is `DOWN` while no container is running.
- Addresses that start with `10.`, `192.168.` or `172.16.` to `172.31.` are private. They work only inside a local network. If your server shows only private addresses, its public address is handled by the provider's router; `--public-ip` shows it.

### Default routes

```text
default via 203.0.113.1 dev eth0
```

The address after `via` is the gateway: the router to which the server sends everything that is not for its own network. No line here means no internet access.

### DNS servers

The servers that translate names such as `example.com` into IP addresses. On Ubuntu you will often see `127.0.0.53`. That is a local helper service (`systemd-resolved`); the real servers are shown by `resolvectl status`.

### Listening ports

```text
Netid State  Recv-Q Send-Q Local Address:Port Peer Address:Port
tcp   LISTEN 0      128          0.0.0.0:22        0.0.0.0:*
tcp   LISTEN 0      511        127.0.0.1:3306      0.0.0.0:*
```

Each line is a program that waits for connections. The important column is `Local Address:Port`:

- `0.0.0.0:22` or `[::]:22` means the program accepts connections from **everywhere**, unless a firewall blocks them.
- `127.0.0.1:3306` means the program accepts connections **only from the server itself**. This is the safe setting for databases.

Some well-known ports:

| Port | Usual service |
| --- | --- |
| 22 | SSH |
| 80 | HTTP (websites) |
| 443 | HTTPS (encrypted websites) |
| 3306 | MySQL or MariaDB |
| 5432 | PostgreSQL |
| 6379 | Redis |
| 27017 | MongoDB |

If a database port is listed with `0.0.0.0`, anyone on the internet can try to connect to it. Change the database configuration so that it listens on `127.0.0.1`, or block the port with the firewall.

## Answers to common questions

**What is the public IP address of my server?**

```bash
ready-fast run network-info --public-ip
```

**Does the internet connection work?**

```bash
ready-fast run network-info --check
```

Both test lines should end with `OK`. If the DNS test fails, names cannot be resolved; if only the HTTPS test fails, outgoing connections are blocked somewhere.

**Which program is using a port?** Run the report with `sudo` and look at the end of the line in the "Listening ports" section. The text `users:(("nginx",pid=812,fd=6))` means the program `nginx` with process number 812.

**Why can nobody reach my service from outside?** Check these three things in order:

1. The program listens on `0.0.0.0` or `[::]`, not only on `127.0.0.1`.
2. The firewall on the server allows the port. See [Firewall](firewall.md).
3. The firewall of your hosting provider (often called "security group" or "cloud firewall") allows the port too.

## Before you turn on a firewall

Run the report first and note every port that must stay reachable from outside. Then give exactly these ports to [firewall-setup](scripts/firewall-setup.md). This avoids the most common mistake: turning on a firewall and blocking a service you forgot.

## What ready-fast does not do

ready-fast has no script that changes the network configuration. It does not set static IP addresses, change DNS servers, create VPN connections or tune kernel network parameters. On Ubuntu the network is configured in `/etc/netplan/`, on Debian usually in `/etc/network/interfaces`; follow the documentation of your distribution or provider for such changes.

## More help

Problems and error messages of the script are listed in [network-info](scripts/network-info.md). General help is in [Troubleshooting](troubleshooting.md).
