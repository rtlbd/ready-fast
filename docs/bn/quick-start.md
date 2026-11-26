# দ্রুত শুরু

🌐 [English](../en/quick-start.md) | **বাংলা**

[← ডকুমেন্টেশনের মূল পাতা](README.md)

এই পাতাটি আপনাকে মোটামুটি দশ মিনিটে একটি ফাঁকা সার্ভার থেকে ready-fast-এর প্রথম কমান্ডগুলো পর্যন্ত নিয়ে যাবে। Linux-এ আগের অভিজ্ঞতা না থাকলেও চলবে; প্রতিটি কমান্ড ব্যাখ্যা করা আছে।

## শুরু করার আগে

- আপনার দরকার Ubuntu 22.04, 24.04, 26.04 অথবা Debian 12, 13-এর একটি সার্ভার এবং `sudo` ব্যবহার করতে পারেন এমন একজন ব্যবহারকারী।
- এটি যদি গুরুত্বপূর্ণ ডেটাসহ সত্যিকারের কোনো সার্ভার হয়, তাহলে কোনো স্ক্রিপ্ট চালানোর আগে তার পাতাটি পড়ে নিন।
- শুরু থেকেই একটি নিয়ম মনে রাখুন: **আগে দেখে নিন, তারপর চালান।**

## ধাপ 1 — ready-fast ইনস্টল করুন

```bash
sudo apt-get update
sudo apt-get install -y git
git clone https://github.com/rtlbd/ready-fast.git
cd ready-fast
sudo ./install.sh
```

এই লাইনগুলো `git` ইনস্টল করে, ready-fast ডাউনলোড করে এবং `ready-fast` কমান্ডটি ইনস্টল করে। প্রতিটি লাইনের ব্যাখ্যা আছে [ইনস্টলেশন](installation.md) পাতায়।

## ধাপ 2 — আপনার সিস্টেম পরীক্ষা করুন

```bash
ready-fast doctor
```

এই কমান্ডটি শুধু তথ্য পড়ে এবং এর জন্য root permission লাগে না। আপনার অপারেটিং সিস্টেম সমর্থিত কি না এবং কোন কোন টুল আছে, তা এটি জানিয়ে দেয়। শেষ লাইনটি এ রকম হওয়া উচিত:

```text
[OK] This system is ready for ready-fast.
```

## ধাপ 3 — কী কী আছে দেখে নিন

```bash
ready-fast list
```

প্রত্যাশিত আউটপুট:

```text
SCRIPT             ROOT       DESCRIPTION
backup-create      depends    Create a compressed tar.gz backup of files or directories, with a SHA-256 checksum
backup-restore     depends    Verify, list or extract a backup archive created by backup-create
docker-install     yes        Install Docker Engine and the Compose plugin from Docker's official apt repository
firewall-setup     yes        Configure the UFW firewall: deny incoming traffic, keep SSH open, allow chosen ports
network-info       no         Show network interfaces, routes, DNS servers and listening ports (read-only)
ssh-hardening      yes        Apply safer OpenSSH server settings through a drop-in file, with built-in rollback
system-monitor     no         Report CPU load, memory, disk usage and failed services, with warning thresholds (read-only)
```

`ROOT` কলামটি থেকে বোঝা যায় স্ক্রিপ্টটির জন্য `sudo` লাগবে কি না: `yes` মানে সবসময় লাগবে, `no` মানে কখনোই লাগবে না, আর `depends` মানে শুধু তখনই লাগবে যখন আপনি যে ফাইলগুলো নিয়ে কাজ করছেন সেগুলোর জন্য দরকার হয়।

কোনো একটি স্ক্রিপ্টের সাহায্য-বার্তা পড়তে:

```bash
ready-fast info docker-install
```

## ধাপ 4 — শুধু তথ্য পড়ে এমন স্ক্রিপ্টগুলো চালিয়ে দেখুন

এই দুটি স্ক্রিপ্ট কোনো কিছু নষ্ট করতে পারে না, কারণ এগুলো শুধু তথ্য পড়ে। টুলটির সাথে পরিচিত হওয়ার জন্য এগুলোই সবচেয়ে ভালো উপায়।

```bash
ready-fast run system-monitor
ready-fast run network-info
```

প্রথমটি সার্ভারের অবস্থার রিপোর্ট দেখায় (CPU load, memory, ডিস্ক)। দ্বিতীয়টি নেটওয়ার্ক কনফিগারেশন দেখায় (IP address, DNS server, খোলা port)। বিস্তারিত: [system-monitor](scripts/system-monitor.md) ও [network-info](scripts/network-info.md)।

## ধাপ 5 — আগে দেখে নিন, তারপর সিস্টেম বদলায় এমন একটি স্ক্রিপ্ট চালান

প্রথম উদাহরণ হিসেবে Docker ইনস্টল করা বেশ ভালো। Preview দিয়ে শুরু করুন:

```bash
sudo ready-fast run docker-install --dry-run
```

`--dry-run` দিলে স্ক্রিপ্টটি যেসব কমান্ড চালাত তার প্রতিটি `[DRY-RUN]` চিহ্নসহ দেখায়, কিন্তু কিছুই পরিবর্তন করে না। তালিকাটি পড়ুন। সব ঠিক মনে হলে স্ক্রিপ্টটি এবার সত্যিই চালান:

```bash
sudo ready-fast run docker-install
```

স্ক্রিপ্টটি একটি সারসংক্ষেপ দেখিয়ে নিশ্চিতকরণ চাইবে। `y` লিখে Enter চাপুন। কাজ শেষ হলে Docker পরীক্ষা করুন:

```bash
sudo docker run --rm hello-world
```

এই কমান্ডটি ছোট্ট একটি পরীক্ষামূলক image ডাউনলোড করে, একবার চালায় এবং container-টি আবার মুছে ফেলে। `Hello from Docker!` দিয়ে শুরু হওয়া একটি বার্তা দেখলে বুঝবেন সবকিছু ঠিকঠাক কাজ করছে। বিস্তারিত আছে [docker-install](scripts/docker-install.md) পাতায়।

## নতুন সার্ভারের জন্য একটি যুক্তিসংগত ক্রম

একদম নতুন সার্ভার সেটআপ করার সময় এই ক্রমটি মেনে চললে প্রতিটি ধাপে আপনি নিরাপদ থাকবেন। প্রতিটি স্ক্রিপ্ট চালানোর আগে অবশ্যই `--dry-run` দিয়ে preview দেখে নিন।

| ক্রম | উদ্দেশ্য | কমান্ড |
| --- | --- | --- |
| 1 | মূল কনফিগারেশন সংরক্ষণ করা | `sudo ready-fast run backup-create --source /etc --name etc-original` |
| 2 | SSH আরও নিরাপদ করা | `sudo ready-fast run ssh-hardening` |
| 3 | Firewall চালু করা (এখানে web server-এর জন্য) | `sudo ready-fast run firewall-setup --web` |
| 4 | দরকার হলে Docker ইনস্টল করা | `sudo ready-fast run docker-install` |
| 5 | সার্ভারের অবস্থা পরীক্ষা করা | `ready-fast run system-monitor` |

2 ও 3 নম্বর ধাপের পর চলমান SSH সেশনটি খোলা রাখুন এবং দ্বিতীয় একটি টার্মিনাল থেকে নিশ্চিত হয়ে নিন যে এখনো লগইন করা যাচ্ছে।

## তিনটি নিয়ম মনে রাখুন

1. **আগে দেখে নিন।** কোনো কিছু বদলায় এমন প্রতিটি স্ক্রিপ্টের আগে `--dry-run` ব্যবহার করুন।
2. **একমাত্র সেশনটি কখনো বন্ধ করবেন না।** SSH বা firewall-এর সেটিং বদলানোর পর লগআউট করার আগে নতুন একটি লগইন পরীক্ষা করুন।
3. **ফেরার পথ জেনে রাখুন।** প্রতিটি স্ক্রিপ্টের পাতায় "আগের অবস্থায় ফিরে যাওয়া (Rollback)" নামে একটি অংশ আছে। প্রয়োজন পড়ার আগেই সেটি পড়ে রাখুন।

## এরপর কোথায় যাবেন

- সব কমান্ড ও অপশন: [কমান্ড রেফারেন্স](commands.md)
- নতুন সার্ভার সুরক্ষিত করা: [নিরাপত্তা](security.md)
- কিছু একটা কাজ করছে না: [সমস্যা সমাধান](troubleshooting.md)
