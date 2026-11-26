# কমান্ড রেফারেন্স

🌐 [English](../en/commands.md) | **বাংলা**

[← ডকুমেন্টেশনের মূল পাতা](README.md)

এই পাতায় `ready-fast` প্রোগ্রামের প্রতিটি কমান্ড, প্রতিটি স্ক্রিপ্ট এবং প্রতিটি অপশনের তালিকা আছে। কমান্ড, স্ক্রিপ্টের নাম ও অপশনগুলো ঠিক যেভাবে টাইপ করতে হবে সেভাবেই লেখা হয়েছে।

## লেখার নিয়ম (Syntax)

```bash
ready-fast <command> [arguments]
```

`<command>` হলো নিচের টেবিলের শব্দগুলোর যেকোনো একটি। কোনো স্ক্রিপ্টের জন্য root permission লাগলে পুরো লাইনের শুরুতে `sudo` বসান।

## কমান্ডসমূহ

| কমান্ড | কী কাজ করে | Root লাগে কি না |
| --- | --- | --- |
| `ready-fast list` | সব স্ক্রিপ্টের তালিকা দেখায়। | না |
| `ready-fast run <script> [options]` | একটি স্ক্রিপ্ট চালায়। | স্ক্রিপ্টের ওপর নির্ভর করে |
| `ready-fast info <script>` | একটি স্ক্রিপ্টের সাহায্য-বার্তা দেখায়। | না |
| `ready-fast doctor` | এই সিস্টেম সমর্থিত ও প্রস্তুত কি না তা পরীক্ষা করে। | না |
| `ready-fast version` | ইনস্টল থাকা ভার্সন দেখায়। | না |
| `ready-fast help` | সব কমান্ডের সংক্ষিপ্ত বিবরণ দেখায়। | না |

### ready-fast list

```bash
ready-fast list
```

প্রতিটি স্ক্রিপ্টের জন্য তিন কলামের একটি করে লাইন দেখায়: নাম (`SCRIPT`), root লাগে কি না (`ROOT`: `yes`, `no` অথবা `depends`) এবং এক লাইনের বিবরণ (`DESCRIPTION`)। সম্পূর্ণ আউটপুট দেখানো আছে [দ্রুত শুরু](quick-start.md) পাতায়।

### ready-fast run

```bash
sudo ready-fast run docker-install --dry-run
```

`run`-এর পরে যে স্ক্রিপ্টের নাম থাকে, সেটি চালায়। স্ক্রিপ্টের নামের পরে যা কিছু লেখা হয়, সবই অপশন হিসেবে স্ক্রিপ্টের কাছে চলে যায়। নামটি অজানা হলে কমান্ডটি exit status 2 দিয়ে থেমে যায় এবং `ready-fast list` ব্যবহার করতে বলে।

### ready-fast info

```bash
ready-fast info firewall-setup
```

একটি স্ক্রিপ্টের নিজস্ব সাহায্য-বার্তা দেখায়: সেটি কী করে এবং কোন কোন অপশন গ্রহণ করে। স্ক্রিপ্টটি `--help` দিয়ে চালালে যে ফল পাওয়া যায়, এতেও তা-ই পাওয়া যায়। কিছুই পরিবর্তন হয় না।

### ready-fast doctor

```bash
ready-fast doctor
```

অপারেটিং সিস্টেম, CPU architecture, আপনি root কি না, systemd চালু আছে কি না এবং আবশ্যক ও ঐচ্ছিক কোন কোন টুল ইনস্টল আছে, তা দেখায়। সিস্টেম প্রস্তুত থাকলে exit status হয় 0; অপারেটিং সিস্টেম বা architecture সমর্থিত না হলে অথবা আবশ্যক কোনো টুল না থাকলে হয় 1। আউটপুটের নমুনা আছে [ইনস্টলেশন](installation.md) পাতায়।

### ready-fast version

```bash
ready-fast version
```

```text
ready-fast 0.1.0
```

### ready-fast help

```bash
ready-fast help
```

কয়েকটি উদাহরণসহ কমান্ডগুলোর তালিকা দেখায়। কোনো কমান্ড ছাড়া শুধু `ready-fast` চালালেও একই লেখা দেখা যায়।

## স্ক্রিপ্ট ও সেগুলোর অপশন

প্রতিটি স্ক্রিপ্টের বিস্তারিত ব্যাখ্যাসহ নিজস্ব পাতা আছে। এই অংশটি সংক্ষিপ্ত রেফারেন্স।

### docker-install

Docker Engine ও Compose plugin ইনস্টল করে। Root লাগে: হ্যাঁ। বিস্তারিত পাতা: [docker-install](scripts/docker-install.md)।

```bash
sudo ready-fast run docker-install --user deploy
```

| অপশন | অর্থ |
| --- | --- |
| `--user <name>` | আগে থেকে থাকা এই ব্যবহারকারীকে `docker` গ্রুপেও যোগ করে। |
| `--dry-run` | কী কী করা হবে তা দেখায়, কিন্তু কিছুই পরিবর্তন করে না। |
| `--yes` | নিশ্চিতকরণের প্রশ্ন জিজ্ঞেস করে না। |
| `--help` | সাহায্য-বার্তা দেখায়। |

### firewall-setup

UFW firewall কনফিগার করে। Root লাগে: হ্যাঁ। বিস্তারিত পাতা: [firewall-setup](scripts/firewall-setup.md)।

```bash
sudo ready-fast run firewall-setup --ssh-port 2222 --web --allow 51820/udp
```

| অপশন | অর্থ |
| --- | --- |
| `--ssh-port <port>` | যে SSH port খোলা রাখতে হবে। ডিফল্ট: নিজে থেকে শনাক্ত করা হয়, না পারলে 22। |
| `--web` | HTTP (80/tcp) ও HTTPS (443/tcp)-এরও অনুমতি দেয়। |
| `--allow <port[/proto]>` | এই port-টিরও অনুমতি দেয়; `proto` হবে `tcp` অথবা `udp`। একাধিকবার দেওয়া যায়। |
| `--dry-run` | কী কী করা হবে তা দেখায়, কিন্তু কিছুই পরিবর্তন করে না। |
| `--yes` | নিশ্চিতকরণের প্রশ্ন জিজ্ঞেস করে না। |
| `--help` | সাহায্য-বার্তা দেখায়। |

### ssh-hardening

SSH সার্ভারে আরও নিরাপদ সেটিং প্রয়োগ করে। Root লাগে: হ্যাঁ। বিস্তারিত পাতা: [ssh-hardening](scripts/ssh-hardening.md)।

```bash
sudo ready-fast run ssh-hardening --root-login prohibit-password --disable-password-auth
sudo ready-fast run ssh-hardening --rollback
```

| অপশন | অর্থ |
| --- | --- |
| `--root-login <mode>` | `PermitRootLogin`-এর মান `yes`, `prohibit-password` অথবা `no` করে। |
| `--disable-password-auth` | পাসওয়ার্ড দিয়ে লগইন বন্ধ করে; শুধু SSH key কাজ করে। |
| `--rollback` | এই স্ক্রিপ্টের লেখা সেটিংগুলো সরিয়ে SSH reload করে। |
| `--dry-run` | কী কী করা হবে তা দেখায়, কিন্তু কিছুই পরিবর্তন করে না। |
| `--yes` | নিশ্চিতকরণের প্রশ্ন জিজ্ঞেস করে না। |
| `--help` | সাহায্য-বার্তা দেখায়। |

### network-info

নেটওয়ার্ক কনফিগারেশন দেখায়। শুধু তথ্য পড়ে। Root লাগে: না। বিস্তারিত পাতা: [network-info](scripts/network-info.md)।

```bash
ready-fast run network-info --public-ip --check
```

| অপশন | অর্থ |
| --- | --- |
| `--public-ip` | Public IP address-ও দেখায় (`https://api.ipify.org`-এ একটি request যায়)। |
| `--check` | DNS resolution ও বাইরের দিকে HTTPS সংযোগও পরীক্ষা করে। |
| `--help` | সাহায্য-বার্তা দেখায়। |

### system-monitor

সার্ভারের অবস্থার রিপোর্ট দেখায়। শুধু তথ্য পড়ে। Root লাগে: না। বিস্তারিত পাতা: [system-monitor](scripts/system-monitor.md)।

```bash
ready-fast run system-monitor --disk-warn 80 --mem-warn 85
```

| অপশন | অর্থ |
| --- | --- |
| `--disk-warn <percent>` | ডিস্ক ব্যবহারের সতর্কতার সীমা, 1–100। ডিফল্ট: 85। |
| `--mem-warn <percent>` | Memory ব্যবহারের সতর্কতার সীমা, 1–100। ডিফল্ট: 90। |
| `--help` | সাহায্য-বার্তা দেখায়। |

### backup-create

Checksum-সহ একটি compressed ব্যাকআপ archive তৈরি করে। Root লাগে: ফাইলের ওপর নির্ভর করে। বিস্তারিত পাতা: [backup-create](scripts/backup-create.md)।

```bash
sudo ready-fast run backup-create --source /etc --dest /var/backups/ready-fast --name etc --keep 7
```

| অপশন | অর্থ |
| --- | --- |
| `--source <path>` | যে ফাইল বা ডিরেক্টরির ব্যাকআপ নিতে হবে। আবশ্যক; একাধিকবার দেওয়া যায়। |
| `--dest <dir>` | যে ডিরেক্টরিতে archive রাখা হবে। ডিফল্ট: `/var/backups/ready-fast`। |
| `--name <label>` | Archive-এর নামের প্রথম অংশ। ডিফল্ট: `backup`। |
| `--keep <count>` | এই নামের শুধু সবচেয়ে নতুন `<count>`টি archive রাখে। ডিফল্ট: 0 (সব রাখে)। |
| `--dry-run` | কী কী করা হবে তা দেখায়, কিন্তু কিছুই পরিবর্তন করে না। |
| `--help` | সাহায্য-বার্তা দেখায়। |

### backup-restore

ব্যাকআপ archive যাচাই করে, তার তালিকা দেখায় অথবা extract করে। Root লাগে: ফাইলের ওপর নির্ভর করে। বিস্তারিত পাতা: [backup-restore](scripts/backup-restore.md)।

```bash
sudo ready-fast run backup-restore --file /var/backups/ready-fast/etc-20261126-210300.tar.gz --list
sudo ready-fast run backup-restore --file /var/backups/ready-fast/etc-20261126-210300.tar.gz --target /tmp/restore-test
```

| অপশন | অর্থ |
| --- | --- |
| `--file <archive>` | যে archive ব্যবহার করা হবে। আবশ্যক। |
| `--list` | শুধু ভেতরের তালিকা দেখায়; কিছুই extract করে না। |
| `--target <dir>` | যে ডিরেক্টরিতে extract করা হবে। `--list` ব্যবহার না করলে আবশ্যক। |
| `--dry-run` | কী কী করা হবে তা দেখায়, কিন্তু কিছুই পরিবর্তন করে না। |
| `--yes` | নিশ্চিতকরণের প্রশ্ন জিজ্ঞেস করে না। |
| `--help` | সাহায্য-বার্তা দেখায়। |

## একাধিক স্ক্রিপ্টে থাকা অপশন

| অপশন | কোথায় আছে | অর্থ |
| --- | --- | --- |
| `--help` | প্রতিটি স্ক্রিপ্টে | সাহায্য-বার্তা দেখিয়ে বের হয়ে যায়। Root ছাড়াই এবং যেকোনো সিস্টেমে কাজ করে। |
| `--dry-run` | কোনো কিছু বদলায় এমন প্রতিটি স্ক্রিপ্টে | প্রতিটি কমান্ড না চালিয়ে `[DRY-RUN]` চিহ্নসহ দেখায়। যেসব যাচাই শুধু তথ্য পড়ে, সেগুলো তখনো চলে। যেসব স্ক্রিপ্টের জন্য root লাগে, সেগুলোতে `--dry-run`-এর জন্যও root লাগে। |
| `--yes` | `docker-install`, `firewall-setup`, `ssh-hardening`, `backup-restore` | নিশ্চিতকরণের প্রশ্নটি এড়িয়ে যায়। টার্মিনাল না থাকলে (যেমন cron-এ বা অন্য কোনো স্ক্রিপ্টের ভেতরে) `--yes` না দিলে এই স্ক্রিপ্টগুলো এগোতে রাজি হয় না। |

## Exit status

প্রতিটি কমান্ড ও স্ক্রিপ্ট নিচের সংখ্যাগুলোর কোনো একটি দিয়ে শেষ হয়। কমান্ডের ঠিক পরেই `echo $?` চালিয়ে সংখ্যাটি দেখা যায়।

| Status | অর্থ |
| --- | --- |
| 0 | সফল। |
| 1 | কাজটি ব্যর্থ হয়েছে, নিশ্চিতকরণের প্রশ্নে আপনি "না" বলেছেন, অথবা কোনো পরীক্ষায় সতর্কবার্তা এসেছে (`ready-fast doctor`, `system-monitor`, `network-info`)। |
| 2 | ভুল ব্যবহার: অজানা কমান্ড, অজানা স্ক্রিপ্ট অথবা ভুল অপশন। |

## Environment variable

| Variable | অর্থ |
| --- | --- |
| `NO_COLOR` | এতে ফাঁকা নয় এমন যেকোনো মান দেওয়া থাকলে আউটপুট রং ছাড়া দেখানো হয়। আউটপুট টার্মিনালে না গেলেও রং নিজে থেকেই বন্ধ হয়ে যায়। |
| `READY_FAST_OS_RELEASE` | `/etc/os-release`-এর বদলে যে ফাইলটি পড়তে হবে তার path। এটি শুধু স্বয়ংক্রিয় টেস্টের জন্য রাখা হয়েছে। অপারেটিং সিস্টেমের যাচাই এড়ানোর জন্য এটি ব্যবহার করবেন না। |

## Installer

`install.sh` ফাইলটি প্রজেক্টের একদম ওপরের ডিরেক্টরিতে থাকে। এর বিবরণ আছে [ইনস্টলেশন](installation.md) পাতায়।

```bash
sudo ./install.sh
sudo ./install.sh --uninstall
./install.sh --help
```

| অপশন | অর্থ |
| --- | --- |
| (কিছু না দিলে) | Toolkit-টি `/opt/ready-fast`-এ কপি করে এবং `/usr/local/bin/ready-fast` link তৈরি করে। |
| `--uninstall` | `/opt/ready-fast` ও `/usr/local/bin/ready-fast` সরিয়ে ফেলে। |
| `--help` | সাহায্য-বার্তা দেখায়। |

## ready-fast যেসব ফাইল ও ডিরেক্টরি ব্যবহার করে

| Path | কাজ |
| --- | --- |
| `/opt/ready-fast` | ইনস্টল হওয়া toolkit। |
| `/usr/local/bin/ready-fast` | `ready-fast` কমান্ডের link। |
| `/var/backups/ready-fast` | ব্যাকআপ archive রাখার ডিফল্ট ডিরেক্টরি; স্ক্রিপ্ট যেসব ফাইল বদলায় সেগুলোর কপিও এখানে থাকে। |
| `/etc/ssh/sshd_config.d/00-ready-fast.conf` | `ssh-hardening`-এর লেখা SSH সেটিং। |
| `/etc/apt/sources.list.d/docker.list` | Docker-এর apt repository; `docker-install` এটি লেখে। |
| `/etc/apt/keyrings/docker.asc` | Docker-এর signing key; `docker-install` এটি লেখে। |
