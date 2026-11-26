# system-monitor

🌐 **English** | [বাংলা](../../bn/scripts/system-monitor.md)

[← Documentation home](../README.md)

## 1. Introduction

`system-monitor` prints a health report of your server in a few seconds: uptime, CPU load, memory, disk space, failed services and the busiest processes. It compares the numbers with warning thresholds and tells you clearly when something needs attention.

The script only reads information. It installs nothing, runs no background service and keeps no history. Because its exit status shows whether a warning was found, it can also be used from cron. See [Monitoring](../monitoring.md) for scheduling and for help with reading the numbers.

## 2. What it does

- Shows the hostname, the kernel version and how long the server has been running.
- Shows the number of CPU cores and the load average of the last 1, 5 and 15 minutes.
- Shows how much memory and swap is in use.
- Shows how full each local filesystem is.
- Lists systemd services that are in the "failed" state.
- Lists the five processes that use the most CPU.
- Prints a `WARNING:` line for each problem and a final result line.

A warning is raised when:

| Check | Warning condition |
| --- | --- |
| CPU load | The 1-minute load average is higher than the number of CPU cores. |
| Memory | Memory usage has reached the `--mem-warn` threshold (default 90%). |
| Disk | A filesystem has reached the `--disk-warn` threshold (default 85%). |
| Services | At least one systemd unit is in the "failed" state. |

## 3. Supported OS

| Distribution | Versions |
| --- | --- |
| Ubuntu | 22.04, 24.04, 26.04 |
| Debian | 12, 13 |

This script does not check the operating system. It should also work on other Linux distributions, but it is tested only on the systems in the table. See [Supported OS](../supported-os.md).

## 4. Requirements

- Root permission: **not required**.
- Standard tools that are present on every normal server: `df`, `nproc`, `awk` and `ps` (from the `procps` package).
- ready-fast installed (see [Installation](../installation.md)).

## 5. Installation command

Report with the default thresholds:

```bash
ready-fast run system-monitor
```

Report that warns earlier, at 70% disk usage and 80% memory usage:

```bash
ready-fast run system-monitor --disk-warn 70 --mem-warn 80
```

## 6. Step-by-step explanation

**System.** The hostname comes from `hostname`, the kernel version from `uname -r` and the uptime from `/proc/uptime`.

**CPU load.** The number of cores comes from `nproc` and the load averages from `/proc/loadavg`. The load average is the average number of processes that are running or waiting for the CPU. As a rule of thumb, a load that stays above the number of cores means the server has more work than it can handle.

**Memory.** The script reads `MemTotal` and `MemAvailable` from `/proc/meminfo` and calculates used memory as total minus available. "Available" already counts memory that Linux uses as disk cache and can free at any time, so this number is more meaningful than the "free" column of other tools.

**Disk usage.**

```bash
df -P -l -x tmpfs -x devtmpfs -x squashfs -x efivarfs
```

`-P` gives a stable output format, `-l` limits the list to local filesystems, and each `-x` hides a kind of virtual filesystem that is not a real disk. The `Capacity` column is compared with the threshold.

**Failed services.**

```bash
systemctl --failed --no-legend --plain
```

This lists units that systemd tried to start but that ended with an error. If systemd is not running (for example inside a container), the check is skipped.

**Top processes.**

```bash
ps -eo pid,comm,%cpu,%mem --sort=-%cpu
```

Only the first five processes are shown.

**Result.** If no check raised a warning, the script prints `Result: no warnings.` and exits with status 0. Otherwise it prints the number of warnings and exits with status 1.

## 7. Command options

| Option | Meaning |
| --- | --- |
| `--disk-warn <percent>` | Disk usage warning threshold, a number from 1 to 100. Default: 85. |
| `--mem-warn <percent>` | Memory usage warning threshold, a number from 1 to 100. Default: 90. |
| `--help` | Show the help text and exit. |

Exit status: 0 means no warnings, 1 means at least one warning, 2 means an invalid option.

## 8. Expected output

A healthy server:

```text

== System ==
Hostname: web-01
Kernel:   6.8.0-45-generic
Uptime:   12 day(s), 4 hour(s), 31 minute(s)

== CPU load ==
CPU cores: 2
Load average (1, 5, 15 min): 0.07 0.02 0.00

== Memory ==
Memory: 538 MiB used of 1963 MiB (27%)
Swap:   not configured

== Disk usage ==
Filesystem     1024-blocks    Used Available Capacity Mounted on
/dev/vda1         50620216 9187592  41416240      19% /

== Failed services ==
none

== Top processes by CPU ==
    PID COMMAND         %CPU %MEM
   1042 dockerd          0.4  3.9
    901 containerd       0.2  2.1
    812 sshd             0.0  0.4
      1 systemd          0.0  0.6
    455 cron             0.0  0.1

[OK] Result: no warnings.
```

When a threshold is reached, a warning line appears in the matching section and the result line changes:

```text
WARNING: filesystem / is 91% full (threshold 85%)
```

```text
[WARN] Result: 1 warning(s).
```

## 9. Security considerations

- The script is read-only and needs no root permission.
- The report shows process names, the hostname and the disk layout. Check it before you share it publicly.
- This is a quick check, not a monitoring system. It does not send alerts, does not watch the server continuously and does not replace tools such as Prometheus, Netdata or the monitoring of your hosting provider.

## 10. Side effects

None. No files are written, no packages are installed and no settings are changed.

## 11. Rollback instructions

Nothing needs to be rolled back, because the script does not change the system. If you scheduled it with cron, remove that line from your crontab; see [Monitoring](../monitoring.md).

## 12. Troubleshooting

| Problem | Cause and solution |
| --- | --- |
| The script exits with status 1 although nothing looks broken | At least one `WARNING:` line was printed. Read the report from the top; the warning is in the section it belongs to. |
| A filesystem that is always full (for example a read-only image) causes a warning every time | Raise the threshold with `--disk-warn`. Excluding single filesystems is not supported. |
| Memory usage looks lower than in `top` or `free` | The script counts memory that can be freed at any time (disk cache) as available. This is intended. |
| `(systemd is not running; skipped)` | The machine is a container or does not use systemd, so failed services cannot be listed. |
| `(the 'ps' command is missing; install the procps package)` | Install it with `sudo apt-get install -y procps`. |
| `Invalid --disk-warn value` or `Invalid --mem-warn value` | The threshold must be a whole number from 1 to 100, without the `%` sign. |

More general problems are covered in [Troubleshooting](../troubleshooting.md).

## 13. Testing status

| What | How it is tested |
| --- | --- |
| Shell syntax and common mistakes | `shellcheck` in CI on every push |
| Option validation and a basic run | `tests/smoke.sh` in CI, on a GitHub-hosted Ubuntu virtual machine and inside `amd64` containers of Ubuntu 22.04, 24.04, 26.04 and Debian 12, 13 |
| Correctness of each warning under real high load, full memory or a full disk | Not tested automatically |
| `arm64` | Not tested |
