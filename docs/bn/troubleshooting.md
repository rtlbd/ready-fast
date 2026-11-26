# সমস্যা সমাধান

🌐 [English](../en/troubleshooting.md) | **বাংলা**

[← ডকুমেন্টেশনের মূল পাতা](README.md)

ready-fast-এর যেকোনো কমান্ডে যেসব সমস্যা হতে পারে, সেগুলো এই পাতায় একসাথে রাখা হয়েছে। নির্দিষ্ট কোনো স্ক্রিপ্টের নিজস্ব সমস্যাগুলো সেই স্ক্রিপ্টের পাতার "সমস্যা সমাধান" অংশে আছে; link-গুলো এই পাতার শেষে দেওয়া আছে।

## যেকোনো সমস্যায় প্রথম করণীয়

1. **আউটপুটের শেষ লাইনগুলো পড়ুন।** `[ERROR]` দিয়ে শুরু হওয়া লাইনে লেখা থাকে কী ভুল হয়েছে এবং সাধারণত কী করতে হবে সেটাও।
2. **সিস্টেম পরীক্ষা করুন:**

```bash
ready-fast doctor
```

3. **স্ক্রিপ্টটি preview মোডে চালান**; এতে কিছু না বদলেই দেখা যায় সেটি কী করার চেষ্টা করছে:

```bash
sudo ready-fast run firewall-setup --dry-run
```

4. **স্ক্রিপ্টের সাহায্য-বার্তা পড়ুন**, অপশনের বানান ঠিক আছে কি না মিলিয়ে নিতে:

```bash
ready-fast info firewall-setup
```

## ready-fast কমান্ডের বার্তা

| বার্তা | কারণ ও সমাধান |
| --- | --- |
| `ready-fast: command not found` | ready-fast ইনস্টল করা নেই, অথবা `/usr/local/bin` আপনার `PATH`-এ নেই। [ইনস্টলেশন](installation.md) পাতার নিয়মে ইনস্টল করুন, অথবা পুরো path `/usr/local/bin/ready-fast` ব্যবহার করুন। |
| `Unknown command` | `ready-fast`-এর পরের শব্দটি কোনো কমান্ড নয়। সঠিক কমান্ডগুলো দেখতে `ready-fast help` চালান। |
| `Unknown script` | স্ক্রিপ্টের নামের বানান ভুল হয়েছে। কোন কোন স্ক্রিপ্ট আছে দেখতে `ready-fast list` চালান। |
| `Unknown option` | স্ক্রিপ্টটিতে এই অপশন নেই। `ready-fast info <script>` দিয়ে অপশনগুলো দেখে নিন। |
| `Option ... requires a value.` | `--user`-এর মতো কোনো অপশনের পরে যে মানটি থাকার কথা, সেটি দেওয়া হয়নি। |

## Permission ও নিশ্চিতকরণ

| বার্তা | কারণ ও সমাধান |
| --- | --- |
| `This script must be run as root. Re-run it with sudo.` | পুরো কমান্ডের শুরুতে `sudo` বসান। |
| `sudo: command not found` | আপনি এমন একটি minimal সিস্টেমে আছেন, যেখানে `sudo` নেই। `root` হিসেবে লগইন করে `sudo` ছাড়াই কমান্ডটি চালান। |
| `... is not in the sudoers file` | আপনার ব্যবহারকারীর `sudo` ব্যবহারের অনুমতি নেই। Administrator-কে বলুন, অথবা `root` হিসেবে লগইন করে নিজের user name বসিয়ে `usermod -aG sudo deploy` চালান, তারপর আবার লগইন করুন। |
| `Confirmation is required but no terminal is attached. Re-run with --yes to continue without a prompt.` | কমান্ডটি এমন জায়গায় চলছে যেখানে প্রশ্ন করা সম্ভব নয়, যেমন cron-এ বা কোনো pipe-এর ভেতর দিয়ে। কাজটির ব্যাপারে আপনি নিশ্চিত হলে `--yes` যোগ করুন। |
| `Cancelled. No changes were made.` | নিশ্চিতকরণের প্রশ্নে আপনি `y` ছাড়া অন্য কিছু উত্তর দিয়েছেন। ভুল করে দিয়ে থাকলে কমান্ডটি আবার চালান। |

## অপারেটিং সিস্টেম

| বার্তা | কারণ ও সমাধান |
| --- | --- |
| `Unsupported operating system` | স্ক্রিপ্টটি শুধু [সমর্থিত অপারেটিং সিস্টেম](supported-os.md) পাতার তালিকার সিস্টেমগুলোতে চলে। এই যাচাই বন্ধ করা যায় না। |
| `Unsupported CPU architecture` | `docker-install` শুধু `amd64` ও `arm64` সমর্থন করে। |
| `VERSION_CODENAME is missing from the os-release file` | `/etc/os-release` ফাইলটি অসম্পূর্ণ; অস্বাভাবিক বা পরিবর্তিত সিস্টেমে এমন হয়। সেখানে ready-fast ব্যবহার করা যাবে না। |

## প্যাকেজ ইনস্টল করা (apt)

`docker-install` ও `firewall-setup` `apt-get` দিয়ে প্যাকেজ ইনস্টল করে। এই স্ক্রিপ্টগুলোর বেশির ভাগ ব্যর্থতার কারণ আসলে apt নিজেই।

| বার্তা | কারণ ও সমাধান |
| --- | --- |
| `Could not get lock /var/lib/dpkg/lock-frontend` | প্যাকেজ-সংক্রান্ত অন্য একটি কাজ চলছে; বুটের ঠিক পরপর প্রায়ই স্বয়ংক্রিয় আপডেট চলে। ready-fast সর্বোচ্চ 120 সেকেন্ড অপেক্ষা করে। এরপরও ব্যর্থ হলে কয়েক মিনিট অপেক্ষা করে স্ক্রিপ্টটি আবার চালান। |
| `dpkg was interrupted, you must manually run 'sudo dpkg --configure -a'` | আগের কোনো ইনস্টলেশন মাঝপথে থেমে গিয়েছিল। বার্তায় দেখানো কমান্ডটি হুবহু চালান, তারপর স্ক্রিপ্টটি আবার চালান। |
| `Unable to locate package` | প্যাকেজের তালিকা পুরোনো হয়ে গেছে অথবা software source অসম্পূর্ণ। `sudo apt-get update` চালান এবং এর আউটপুটে কোনো error আছে কি না দেখুন। |
| `Temporary failure resolving` অথবা `Could not resolve` | DNS কাজ করছে না। পরের অংশটি দেখুন। |
| `Release file ... is not valid yet` | সার্ভারের ঘড়ির সময় ভুল। `date` দিয়ে সময় দেখুন এবং `sudo timedatectl set-ntp true` দিয়ে সময়ের synchronisation চালু করুন। |

## নেটওয়ার্ক

নেটওয়ার্ক রিপোর্ট ও তার নিজস্ব পরীক্ষাগুলো দিয়ে শুরু করুন:

```bash
ready-fast run network-info --check
```

- `(no default route)`: সার্ভারের কোনো gateway নেই। আপনার provider-এর control panel-এ নেটওয়ার্ক সেটিং পরীক্ষা করুন।
- `DNS resolution (example.com): FAILED`: রিপোর্টে দেখানো DNS server-গুলো সাড়া দিচ্ছে না।
- DNS `OK`, কিন্তু HTTPS ব্যর্থ: সার্ভারের বাইরের কোনো firewall বাইরের দিকে সংযোগ আটকে দিচ্ছে, অথবা সার্ভারটিকে proxy ব্যবহার করতে হবে।

আরও ব্যাখ্যা আছে [নেটওয়ার্কিং](networking.md) পাতায়।

## সার্ভারের বাইরে আটকে পড়লে

SSH বা firewall-এর সেটিং বদলানোর পর SSH দিয়ে আর লগইন করতে না পারলে:

1. এখনো খোলা আছে এমন কোনো SSH সেশন বন্ধ করবেন না। সেটি দিয়েই পরিবর্তনটি বাতিল করুন।
2. তা না থাকলে আপনার hosting provider-এর control panel থেকে web console (অনেক সময় VNC, KVM বা serial console নামে থাকে) খুলে সেখানে লগইন করুন।
3. শেষ পরিবর্তনটি বাতিল করুন:

```bash
sudo ready-fast run ssh-hardening --rollback
sudo ufw disable
```

প্রথম লাইনটি ready-fast-এর লেখা SSH সেটিংগুলো সরিয়ে দেয়। দ্বিতীয় লাইনটি firewall বন্ধ করে; এর rule-গুলো থেকে যায়। এরপর আবার চেষ্টা করার আগে সমস্যার কারণটি খুঁজে বের করুন।

## কোনো স্ক্রিপ্ট মাঝপথে থেমে গেলে

স্ক্রিপ্টগুলো এমনভাবে লেখা, যাতে নিরাপদে আবার চালানো যায়:

- Docker আগে থেকে ইনস্টল থাকলে `docker-install` ইনস্টলেশন বাদ দিয়ে যায়। আগে মাঝপথে থেমে গিয়ে থাকলে আবার চালান; apt যেখানে থেমেছিল সেখান থেকেই চালিয়ে যায়।
- আগে থেকে থাকা rule `firewall-setup` দ্বিতীয়বার যোগ করে না।
- `ssh-hardening` নিজের ফাইলটি আবার শুরু থেকে লেখে।
- `backup-create` ব্যর্থ হলে অসম্পূর্ণ archive-টি মুছে ফেলে।

## নির্দিষ্ট কোনো স্ক্রিপ্টের সমস্যা

| স্ক্রিপ্ট | সমস্যা সমাধানের অংশ |
| --- | --- |
| docker-install | [docker-install](scripts/docker-install.md) |
| firewall-setup | [firewall-setup](scripts/firewall-setup.md) |
| ssh-hardening | [ssh-hardening](scripts/ssh-hardening.md) |
| network-info | [network-info](scripts/network-info.md) |
| system-monitor | [system-monitor](scripts/system-monitor.md) |
| backup-create | [backup-create](scripts/backup-create.md) |
| backup-restore | [backup-restore](scripts/backup-restore.md) |

## সমস্যা জানানো

সমস্যাটি নিজে সমাধান করতে না পারলে `https://github.com/rtlbd/ready-fast/issues`-এ একটি issue খুলুন। সাথে এই তিনটি কমান্ডের আউটপুট দিন:

```bash
ready-fast version
ready-fast doctor
cat /etc/os-release
```

আপনি ঠিক কোন কমান্ডটি চালিয়েছিলেন এবং তার সম্পূর্ণ আউটপুটও দিন। পোস্ট করার আগে পাসওয়ার্ড, key এবং চাইলে IP address মুছে দিন। Issue-টি ইংরেজি বা বাংলা, যেকোনো ভাষায় লিখতে পারেন।
