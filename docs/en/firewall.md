# Firewall

🌐 **English** | [বাংলা](../bn/firewall.md)

[← Documentation home](README.md)

A firewall is a gatekeeper for network connections. It decides which connections from the internet may reach the programs on your server. Without one, every program that listens on a port can be contacted by anyone.

ready-fast uses UFW (Uncomplicated Firewall), the standard firewall tool of Ubuntu and Debian. This guide shows typical setups and how to manage rules afterwards. The exact behaviour of the script is documented in [firewall-setup](scripts/firewall-setup.md).

## The basic idea

The setup that ready-fast creates follows one simple rule:

- **Incoming** connections are blocked, except to the ports you allow.
- **Outgoing** connections, which the server starts itself, are all allowed.

So you only have to answer one question: which ports must be reachable from outside? If you are not sure, look at the list of listening ports first; see [Networking](networking.md).

## Set up the firewall

Always preview first:

```bash
sudo ready-fast run firewall-setup --dry-run
```

- Root permission: required.
- Risk: if the SSH port in the preview is wrong, you can lock yourself out. Read the line that starts with `3. Allow incoming` carefully. Keep your SSH session open until you have tested a new login.

Then choose the command that fits your server:

| Situation | Command |
| --- | --- |
| Only SSH should be reachable | `sudo ready-fast run firewall-setup` |
| Web server (HTTP and HTTPS) | `sudo ready-fast run firewall-setup --web` |
| SSH runs on port 2222 | `sudo ready-fast run firewall-setup --ssh-port 2222` |
| Web server and WireGuard VPN | `sudo ready-fast run firewall-setup --web --allow 51820/udp` |
| An application on TCP port 8080 | `sudo ready-fast run firewall-setup --allow 8080/tcp` |

You can run the script again later with other options. It adds the new rules and keeps the existing ones.

## Check the firewall

```bash
sudo ufw status verbose
```

`Status: active` means the firewall is on. The line `Default:` shows the basic policy, and the table below it lists every allowed port.

To see the rules with numbers, which is useful for deleting one:

```bash
sudo ufw status numbered
```

## Change rules by hand

After the first setup you can manage rules directly with `ufw`. All of these commands need root.

Allow one more port:

```bash
sudo ufw allow 8080/tcp
```

Remove that rule again:

```bash
sudo ufw delete allow 8080/tcp
```

Allow SSH only from one fixed IP address (here `203.0.113.50`):

```bash
sudo ufw allow from 203.0.113.50 to any port 22 proto tcp
```

**Be careful with this rule.** It helps only if you also delete the general rule for port 22, and then you can log in from that one address only. Many home and mobile internet connections get a new IP address regularly. If your address changes, you are locked out. Use this only when you have a fixed IP address or a second way in.

Slow down repeated login attempts on SSH:

```bash
sudo ufw limit 22/tcp
```

This blocks an address for a while when it opens too many connections in a short time.

## Docker and UFW

**Ports published by Docker containers are not protected by UFW.** Docker writes its own firewall rules, and they are checked before the UFW rules. A container started with `-p 8080:80` is reachable from the internet even though `sudo ufw status` does not show port 8080.

How to stay safe:

- Publish private services on the local address only: `-p 127.0.0.1:8080:80`.
- Publish on all addresses only what really must be public.
- Check the result with `sudo ready-fast run network-info`.

See [Docker](docker.md) for more.

## The firewall of your hosting provider

Many providers have their own firewall in front of your server, often called "security group" or "cloud firewall". It works independently of UFW. A connection must be allowed by **both** firewalls. If a port is open in UFW but still unreachable, check the control panel of your provider.

## Turn the firewall off

```bash
sudo ufw disable
```

This stops filtering immediately; your rules are kept and become active again with `sudo ufw enable`. Complete rollback instructions, including how to delete all rules, are in [firewall-setup](scripts/firewall-setup.md).

## What this setup does not do

- It does not limit outgoing connections.
- It does not inspect the content of connections or detect attacks.
- It does not protect ports published by Docker (see above).
- It does not replace keeping your software up to date.

## More help

Error messages and solutions are in the troubleshooting section of [firewall-setup](scripts/firewall-setup.md). If you are locked out, see [Troubleshooting](troubleshooting.md).
