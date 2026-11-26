# ready-fast documentation / ready-fast ডকুমেন্টেশন

[← Project home / প্রজেক্টের মূল পাতা](../README.md)

The documentation is available in two languages. Both describe exactly the same commands and behaviour.

ডকুমেন্টেশন দুটি ভাষায় আছে। দুটিতেই হুবহু একই কমান্ড ও একই আচরণের বর্ণনা দেওয়া হয়েছে।

| | |
| --- | --- |
| 🇧🇩 **বাংলা** | **[bn/README.md](bn/README.md)** |
| 🇬🇧 **English** | **[en/README.md](en/README.md)** |

## Pages / পাতাসমূহ

| English | বাংলা |
| --- | --- |
| [Installation](en/installation.md) | [ইনস্টলেশন](bn/installation.md) |
| [Quick start](en/quick-start.md) | [দ্রুত শুরু](bn/quick-start.md) |
| [Command reference](en/commands.md) | [কমান্ড রেফারেন্স](bn/commands.md) |
| [Supported OS](en/supported-os.md) | [সমর্থিত অপারেটিং সিস্টেম](bn/supported-os.md) |
| [Security](en/security.md) | [নিরাপত্তা](bn/security.md) |
| [Troubleshooting](en/troubleshooting.md) | [সমস্যা সমাধান](bn/troubleshooting.md) |
| [Docker](en/docker.md) | [Docker](bn/docker.md) |
| [Networking](en/networking.md) | [নেটওয়ার্কিং](bn/networking.md) |
| [Firewall](en/firewall.md) | [Firewall](bn/firewall.md) |
| [Monitoring](en/monitoring.md) | [মনিটরিং](bn/monitoring.md) |
| [Backup](en/backup.md) | [ব্যাকআপ](bn/backup.md) |

## Scripts / স্ক্রিপ্টসমূহ

| English | বাংলা |
| --- | --- |
| [docker-install](en/scripts/docker-install.md) | [docker-install](bn/scripts/docker-install.md) |
| [firewall-setup](en/scripts/firewall-setup.md) | [firewall-setup](bn/scripts/firewall-setup.md) |
| [ssh-hardening](en/scripts/ssh-hardening.md) | [ssh-hardening](bn/scripts/ssh-hardening.md) |
| [network-info](en/scripts/network-info.md) | [network-info](bn/scripts/network-info.md) |
| [system-monitor](en/scripts/system-monitor.md) | [system-monitor](bn/scripts/system-monitor.md) |
| [backup-create](en/scripts/backup-create.md) | [backup-create](bn/scripts/backup-create.md) |
| [backup-restore](en/scripts/backup-restore.md) | [backup-restore](bn/scripts/backup-restore.md) |

## Validation / যাচাই

The two languages are kept in sync by an automated check that runs in CI:

দুই ভাষার ডকুমেন্টেশন একই রকম আছে কি না, তা CI-তে চলা একটি স্বয়ংক্রিয় পরীক্ষা দিয়ে যাচাই করা হয়:

```bash
python3 tools/validate-docs.py
```
