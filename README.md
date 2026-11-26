# ⚡ ready-fast

[![CI](https://github.com/rtlbd/ready-fast/actions/workflows/ci.yml/badge.svg)](https://github.com/rtlbd/ready-fast/actions/workflows/ci.yml)

## 🌐 ভাষা বেছে নিন / Choose your language

| | |
| --- | --- |
| 🇧🇩 **বাংলা ডকুমেন্টেশন** | **[docs/bn/README.md](docs/bn/README.md)** |
| 🇬🇧 **English Documentation** | **[docs/en/README.md](docs/en/README.md)** |

---

## 🇧🇩 বাংলা

**এক কমান্ডেই সার্ভার প্রস্তুত!**

Linux Server Setup, Docker, Networking, Security, Monitoring এবং DevOps Automation-এর জন্য একটি Ready-to-Run Toolkit.

ready-fast হলো যত্ন নিয়ে লেখা কিছু shell script-এর সংগ্রহ, যা দিয়ে Ubuntu বা Debian সার্ভারে কয়েক মিনিটেই Docker ইনস্টল করা, firewall চালু করা, SSH সুরক্ষিত করা, সার্ভারের অবস্থা দেখা এবং ব্যাকআপ নেওয়া যায়। প্রতিটি স্ক্রিপ্ট কী করবে তা আগে দেখিয়ে নেয়, বদলানোর আগে আপনার অনুমতি চায় এবং আগের অবস্থায় ফিরে যাওয়ার পথ রাখে।

নতুন Linux ব্যবহারকারী থেকে শুরু করে VPS ও Dedicated Server Administrator, Web Developer, DevOps Engineer এবং Network Administrator, সবার কথা মাথায় রেখেই এর ডকুমেন্টেশন সহজ বাংলায় লেখা হয়েছে।

👉 **শুরু করুন: [বাংলা ডকুমেন্টেশন](docs/bn/README.md)** · [ইনস্টলেশন](docs/bn/installation.md) · [দ্রুত শুরু](docs/bn/quick-start.md) · [কমান্ড রেফারেন্স](docs/bn/commands.md)

## 🇬🇧 English

**One Command. Everything Ready.**

A ready-to-run automation toolkit for Linux server setup, Docker, networking, security, monitoring, and DevOps.

ready-fast is a collection of carefully written shell scripts that install Docker, turn on a firewall, harden SSH, report on server health and create backups on Ubuntu or Debian servers in minutes. Every script can show a preview first, asks before it changes anything, and documents how to roll back.

👉 **Start here: [English documentation](docs/en/README.md)** · [Installation](docs/en/installation.md) · [Quick start](docs/en/quick-start.md) · [Command reference](docs/en/commands.md)

---

## Install / ইনস্টল

```bash
sudo apt-get update
sudo apt-get install -y git
git clone https://github.com/rtlbd/ready-fast.git
cd ready-fast
sudo ./install.sh
ready-fast doctor
```

## Scripts / স্ক্রিপ্টসমূহ

| Script | English | বাংলা |
| --- | --- | --- |
| `docker-install` | [Install Docker Engine](docs/en/scripts/docker-install.md) | [Docker Engine ইনস্টল](docs/bn/scripts/docker-install.md) |
| `firewall-setup` | [Set up the UFW firewall](docs/en/scripts/firewall-setup.md) | [UFW firewall সেটআপ](docs/bn/scripts/firewall-setup.md) |
| `ssh-hardening` | [Harden the SSH server](docs/en/scripts/ssh-hardening.md) | [SSH সার্ভার সুরক্ষিত করা](docs/bn/scripts/ssh-hardening.md) |
| `network-info` | [Network report](docs/en/scripts/network-info.md) | [নেটওয়ার্ক রিপোর্ট](docs/bn/scripts/network-info.md) |
| `system-monitor` | [Server health report](docs/en/scripts/system-monitor.md) | [সার্ভারের অবস্থার রিপোর্ট](docs/bn/scripts/system-monitor.md) |
| `backup-create` | [Create a backup](docs/en/scripts/backup-create.md) | [ব্যাকআপ তৈরি](docs/bn/scripts/backup-create.md) |
| `backup-restore` | [Restore a backup](docs/en/scripts/backup-restore.md) | [ব্যাকআপ restore](docs/bn/scripts/backup-restore.md) |

Supported systems / সমর্থিত সিস্টেম: Ubuntu 22.04, 24.04, 26.04 · Debian 12, 13

## Repository layout

```text
ready-fast            command-line entry point
install.sh            installer and uninstaller
lib/common.sh         helper functions shared by all scripts
scripts/              one file per script
docs/bn/              Bengali documentation
docs/en/              English documentation
tests/smoke.sh        safe tests that change nothing on the machine
tests/system.sh       tests for disposable machines (they install software)
tests/docs-validator.sh  proves that the documentation checks catch drift
tools/validate-docs.py  bilingual documentation checks
.github/workflows/    continuous integration
```

## For contributors / অবদানকারীদের জন্য

Every change must keep the code, the English documentation and the Bengali documentation in sync. Run these checks before you commit:

```bash
shellcheck ready-fast install.sh lib/common.sh scripts/*.sh tests/*.sh
bash tests/smoke.sh
python3 tools/validate-docs.py
bash tests/docs-validator.sh
```

কোডে যেকোনো পরিবর্তনের সাথে ইংরেজি ও বাংলা, দুই ভাষার ডকুমেন্টেশনই একসাথে হালনাগাদ করতে হবে। কোনো অনুবাদ বাদ পড়লে অথবা দুই ভাষার কমান্ড আলাদা হলে CI ব্যর্থ হয়। নিয়মগুলো বিস্তারিত লেখা আছে [বাংলা](docs/bn/README.md) ও [English](docs/en/README.md) ডকুমেন্টেশনের শেষ অংশে।
