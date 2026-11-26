# Monitoring

🌐 **English** | [বাংলা](../bn/monitoring.md)

[← Documentation home](README.md)

Most server problems announce themselves before they become outages: a disk fills up slowly, memory runs short, a service fails after a reboot. This guide shows how to check the health of a server with ready-fast, how to understand the numbers, and how to run the check automatically.

The script behind this guide is documented in [system-monitor](scripts/system-monitor.md). It only reads information and needs no root permission.

## Run a health check

```bash
ready-fast run system-monitor
```

- Root permission: not required.
- Risk: none. Nothing is installed or changed.

The report ends with one of two lines:

```text
[OK] Result: no warnings.
```

```text
[WARN] Result: 1 warning(s).
```

When there are warnings, each one appears as a line that starts with `WARNING:` inside the section it belongs to.

## Understanding the numbers

### CPU load

The load average tells you how many processes, on average, were running or waiting for the CPU. Three numbers are shown: for the last 1, 5 and 15 minutes.

Compare the load with the number of CPU cores. On a server with 2 cores, a load of 2.00 means the CPUs are fully used. A load that stays clearly above the number of cores means work is piling up. A short peak is normal; a high 15-minute value is a real sign of overload.

What to do: look at the "Top processes by CPU" section to see which program is responsible.

### Memory

The report shows used memory as "total minus available". Linux uses free memory as a cache for files and gives it back as soon as programs need it, so a server can look "full" in other tools while it is perfectly healthy. The number in this report already takes that into account.

What to do when memory is above the threshold for a long time: find the program that uses the most, reduce what runs on the server, or move to a plan with more memory.

### Swap

Swap is disk space that the system uses as emergency memory. Many VPS have none ("not configured"), which is fine. If swap exists and is heavily used, the server is short of real memory and will feel slow.

### Disk usage

Each line is a filesystem with its size and how full it is. A full disk is one of the most common causes of failures: databases stop, logins fail, and updates break.

What to do: find the directories that use the most space. For example, for `/var`:

```bash
sudo du -xh --max-depth=1 /var | sort -h
```

`du` adds up the size of each directory, `-x` stays on one filesystem, `--max-depth=1` shows only the first level, and `sort -h` puts the largest at the bottom. Typical culprits are old log files, package caches and Docker images (see [Docker](docker.md)).

### Failed services

Services that systemd could not start, or that crashed. To find out why a service failed (here `nginx` as an example):

```bash
systemctl status nginx
journalctl -u nginx --no-pager -n 50
```

The first line shows the current state and the last few log lines. The second shows the last 50 log lines of the service.

### Top processes

The five processes that use the most CPU at this moment, with their share of CPU and memory.

## Choose your own thresholds

The default thresholds are 85% for disk usage and 90% for memory usage. To be warned earlier:

```bash
ready-fast run system-monitor --disk-warn 70 --mem-warn 80
```

## Use the result in automation

The script ends with exit status 0 when there are no warnings and 1 when there is at least one. Other programs can react to this. A simple example:

```bash
ready-fast run system-monitor || echo "The server needs attention"
```

The text after `||` is printed only when the check reports a warning.

## Run the check regularly with cron

cron is the standard Linux service that runs commands on a schedule. Open the schedule of the root user:

```bash
sudo crontab -e
```

Add this line at the end, then save and close the editor:

```cron
*/15 * * * * /usr/local/bin/ready-fast run system-monitor >> /var/log/ready-fast-monitor.log 2>&1
```

- `*/15 * * * *` means "every 15 minutes".
- The full path `/usr/local/bin/ready-fast` is used because cron knows only a few directories.
- `>> /var/log/ready-fast-monitor.log` appends each report to a log file, and `2>&1` includes error messages.
- Risk: the log file grows with every run, by roughly 150 KB per day at this interval. Delete or shorten it from time to time.

Read the latest report, or search the log for warnings:

```bash
sudo tail -n 40 /var/log/ready-fast-monitor.log
sudo grep WARNING /var/log/ready-fast-monitor.log
```

To stop the schedule, run `sudo crontab -e` again and delete the line. To remove the log, delete `/var/log/ready-fast-monitor.log`.

## Limits of this approach

`system-monitor` is a quick check, not a monitoring system:

- It does not send e-mail, SMS or chat messages.
- It keeps no history and draws no graphs.
- It cannot tell you that the server is down, because it runs on that server.

For important production servers, also use an external service that checks from outside whether your website answers, and consider a full monitoring tool. The monitoring page of your hosting provider is a good start.

## More help

Problems with the script are listed in [system-monitor](scripts/system-monitor.md). General help is in [Troubleshooting](troubleshooting.md).
