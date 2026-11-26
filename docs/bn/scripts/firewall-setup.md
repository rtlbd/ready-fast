# firewall-setup

🌐 [English](../../en/scripts/firewall-setup.md) | **বাংলা**

[← ডকুমেন্টেশনের মূল পাতা](../README.md)

## 1. পরিচিতি

`firewall-setup` স্ক্রিপ্টটি UFW (Uncomplicated Firewall) দিয়ে একটি প্রাথমিক firewall চালু করে। UFW হলো Ubuntu ও Debian-এর প্রচলিত firewall টুল। স্ক্রিপ্টটি চালানোর পর সার্ভার শুধু আপনার বেছে নেওয়া port-গুলোতেই বাইরে থেকে আসা নতুন সংযোগ গ্রহণ করে, আর SSH খোলা থাকে যাতে আপনি সার্ভারে ঢোকার পথ না হারান।

Firewall ঠিক করে দেয় কোন কোন নেটওয়ার্ক সংযোগ আপনার সার্ভার পর্যন্ত পৌঁছাতে পারবে। বিষয়টি আরও ভালোভাবে বুঝতে এবং আরও উদাহরণ দেখতে [Firewall](../firewall.md) গাইডটি পড়ুন।

## 2. কী কাজ করে

- অপারেটিং সিস্টেম সমর্থিত কি না এবং `firewalld` (আরেকটি firewall manager) চালু আছে কি না তা যাচাই করে।
- আপনার SSH সার্ভার কোন port ব্যবহার করছে তা খুঁজে বের করে, যাতে সেটি খোলা রাখা যায়।
- `ufw` প্যাকেজ না থাকলে ইনস্টল করে।
- ডিফল্ট নীতি ঠিক করে: বাইরে থেকে আসা সব সংযোগ বন্ধ, সার্ভার থেকে বাইরে যাওয়া সব সংযোগ খোলা।
- SSH port-এ এবং `--web` বা `--allow` দিয়ে আপনি যেসব port যোগ করেছেন সেগুলোতে বাইরে থেকে সংযোগের অনুমতি দেয়।
- Firewall এখনই চালু করে এবং প্রতিবার বুটের সময় চালু হওয়ার ব্যবস্থা করে।
- শেষে firewall-এর চূড়ান্ত অবস্থা দেখায়।

আগে থেকে থাকা UFW rule-গুলো যেমন আছে তেমনই থাকে। স্ক্রিপ্টটি শুধু rule যোগ করে; কখনো কোনো rule মুছে ফেলে না।

## 3. সমর্থিত অপারেটিং সিস্টেম

| ডিস্ট্রিবিউশন | ভার্সন |
| --- | --- |
| Ubuntu | 22.04, 24.04, 26.04 |
| Debian | 12, 13 |

অন্য যেকোনো সিস্টেমে স্ক্রিপ্টটি কোনো পরিবর্তন করার আগেই থেমে যায়। UFW চালাতে kernel-এর firewall সুবিধা লাগে; container-ভিত্তিক কিছু VPS-এ (OpenVZ, LXC) firewall চালু করা যায় না। বিস্তারিত: [সমর্থিত অপারেটিং সিস্টেম](../supported-os.md)।

## 4. যা যা প্রয়োজন

- Root permission: **অবশ্যই লাগবে**। কমান্ডটি `sudo` দিয়ে চালান। `--dry-run` ব্যবহার করলেও root permission লাগে।
- `ufw` আগে থেকে ইনস্টল না থাকলে আপনার apt mirror পর্যন্ত ইন্টারনেট সংযোগ।
- ready-fast ইনস্টল করা থাকতে হবে ([ইনস্টলেশন](../installation.md) দেখুন)।
- পরামর্শ: সার্ভারে ঢোকার দ্বিতীয় একটি পথ (আপনার hosting provider-এর web console) হাতের কাছে রাখুন, যাতে ভুলবশত নিজেকে আটকে ফেললেও ঢুকতে পারেন।

## 5. ইনস্টলেশন কমান্ড

প্রথমে preview দেখে নিন। এতে কোন কোন rule যোগ হবে তা দেখানো হয়, কিন্তু কিছুই পরিবর্তন হয় না:

```bash
sudo ready-fast run firewall-setup --dry-run
```

সাধারণ firewall, যেখানে শুধু SSH খোলা থাকে:

```bash
sudo ready-fast run firewall-setup
```

Web server (SSH, HTTP ও HTTPS):

```bash
sudo ready-fast run firewall-setup --web
```

Web server এবং তার সাথে UDP port 51820-এ WireGuard VPN:

```bash
sudo ready-fast run firewall-setup --web --allow 51820/udp
```

স্ক্রিপ্টটি rule-গুলোর তালিকা দেখিয়ে জিজ্ঞেস করবে: `Apply these firewall settings? [y/N]:`। `y` দেওয়ার আগে তালিকায় দেখানো SSH port-টি সঠিক কি না মিলিয়ে নিন।

## 6. ধাপে ধাপে ব্যাখ্যা

**ধাপ 1 — SSH port শনাক্ত করা**

স্ক্রিপ্টটি আপনার বর্তমান SSH সংযোগের port (পাওয়া গেলে) এবং `sshd -T` দিয়ে SSH সার্ভারে কনফিগার করা port-গুলো পড়ে। যতগুলো port পাওয়া যায়, সবগুলোর অনুমতি দেওয়া হয়। কিছুই শনাক্ত করা না গেলে port 22 ধরে নেওয়া হয়। `--ssh-port` দিলে port আপনি নিজেই ঠিক করে দেন; সে ক্ষেত্রে SSH সার্ভার অন্য কোনো port ব্যবহার করছে বলে মনে হলে স্ক্রিপ্টটি আপনাকে সতর্ক করে।

**ধাপ 2 — UFW ইনস্টল** (শুধু না থাকলে)

```bash
apt-get update
apt-get install -y ufw
```

প্রথম লাইনটি প্যাকেজের তালিকা হালনাগাদ করে এবং দ্বিতীয়টি UFW ইনস্টল করে। স্ক্রিপ্টটি `apt-get`-কে `DEBIAN_FRONTEND=noninteractive` এবং 120 সেকেন্ডের lock timeout-ও দিয়ে দেয়, যাতে এটি কখনো প্রশ্ন করে থেমে না থাকে এবং প্যাকেজ-সংক্রান্ত অন্য কোনো কাজ চললে অপেক্ষা করে; হুবহু কমান্ডগুলো `--dry-run` দিয়ে দেখে নিতে পারেন।

**ধাপ 3 — ডিফল্ট নীতি ঠিক করা**

```bash
ufw default deny incoming
ufw default allow outgoing
```

প্রথম লাইনটি বাইরে থেকে আসা প্রতিটি নতুন সংযোগ বন্ধ করে দেয়, যদি না কোনো rule সেটির অনুমতি দেয়। দ্বিতীয় লাইনটি সার্ভারকে নিজে থেকে বাইরে সংযোগ করতে দেয়, যেমন আপডেট ডাউনলোড করার জন্য।

**ধাপ 4 — অনুমতির rule যোগ করা**

```bash
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
```

SSH port এবং আপনার চাওয়া প্রতিটি port-এর জন্য একটি করে `ufw allow` কমান্ড চালানো হয়। এই উদাহরণে `--web` ব্যবহার করা হয়েছে, তাই 80/tcp (HTTP) ও 443/tcp (HTTPS) যোগ হয়েছে।

**ধাপ 5 — firewall চালু করা**

```bash
ufw --force enable
```

এতে rule-গুলো এখনই এবং প্রতিবার রিবুটের পর কার্যকর হয়। `ufw --force enable` রূপটি শুধু UFW-এর নিজের "আপনি কি নিশ্চিত?" প্রশ্নটি এড়িয়ে যায়, কারণ স্ক্রিপ্টটি আগেই আপনাকে জিজ্ঞেস করে নিয়েছে।

**ধাপ 6 — ফলাফল দেখানো**

```bash
ufw status verbose
```

## 7. কমান্ড অপশন

| অপশন | অর্থ |
| --- | --- |
| `--ssh-port <port>` | যে SSH port খোলা রাখতে হবে। এই অপশন না দিলে port নিজে থেকেই শনাক্ত করা হয়; শনাক্ত করা না গেলে 22 ব্যবহার করা হয়। |
| `--web` | HTTP (80/tcp) ও HTTPS (443/tcp)-এরও অনুমতি দেয়। |
| `--allow <port[/proto]>` | এই port-টিরও অনুমতি দেয়। `proto` হবে `tcp` অথবা `udp`; না দিলে দুই protocol-ই খুলে যায়। অপশনটি একাধিকবার দেওয়া যায়। |
| `--dry-run` | কী কী করা হবে তা দেখায়, কিন্তু কিছুই পরিবর্তন করে না। |
| `--yes` | নিশ্চিতকরণের প্রশ্ন জিজ্ঞেস করে না। |
| `--help` | সাহায্য-বার্তা দেখিয়ে বের হয়ে যায়। |

## 8. প্রত্যাশিত আউটপুট

যে সার্ভারে SSH port 22 ব্যবহার করে, সেখানে `sudo ready-fast run firewall-setup --dry-run --web --allow 51820/udp` চালালে এই আউটপুট আসে:

```text
[INFO] System: Ubuntu 24.04.5 LTS
[INFO] The following will be done:
[INFO]   1. Install the package ufw (if missing)
[INFO]   2. Default policy: deny incoming, allow outgoing
[INFO]   3. Allow incoming: 22/tcp 80/tcp 443/tcp 51820/udp
[INFO]   4. Enable the firewall now and at every boot
[WARN] If the SSH port above is wrong, you can lock yourself out of this server.
[INFO] Step 1/4: installing ufw
[INFO] ufw is already installed.
[INFO] Step 2/4: setting the default policy
[DRY-RUN] ufw default deny incoming
[DRY-RUN] ufw default allow outgoing
[INFO] Step 3/4: adding allow rules
[DRY-RUN] ufw allow 22/tcp
[DRY-RUN] ufw allow 80/tcp
[DRY-RUN] ufw allow 443/tcp
[DRY-RUN] ufw allow 51820/udp
[INFO] Step 4/4: enabling the firewall
[DRY-RUN] ufw --force enable
[OK] Dry run finished. Nothing was changed.
```

সত্যিকারের রানে একই `[INFO]` লাইনগুলো আসে, `[DRY-RUN]` লাইনগুলোর জায়গায় প্রতিটি `ufw` কমান্ডের নিজস্ব বার্তা আসে, আর শেষে firewall-এর অবস্থা দেখানো হয়:

```text
Status: active
Logging: on (low)
Default: deny (incoming), allow (outgoing), disabled (routed)
New profiles: skip

To                         Action      From
--                         ------      ----
22/tcp                     ALLOW IN    Anywhere
80/tcp                     ALLOW IN    Anywhere
443/tcp                    ALLOW IN    Anywhere
51820/udp                  ALLOW IN    Anywhere
22/tcp (v6)                ALLOW IN    Anywhere (v6)
80/tcp (v6)                ALLOW IN    Anywhere (v6)
443/tcp (v6)               ALLOW IN    Anywhere (v6)
51820/udp (v6)             ALLOW IN    Anywhere (v6)

[OK] The firewall is active. Keep this session open and confirm that a new SSH login still works.
```

## 9. নিরাপত্তা বিষয়ক সতর্কতা

- **নিজেকে সার্ভারের বাইরে আটকে ফেলার ঝুঁকি।** Rule-এর তালিকায় SSH port ভুল থাকলে নতুন করে SSH লগইন করা যাবে না। নিশ্চিত করার আগে অবশ্যই তালিকাটি পড়ে নিন, চলমান সেশনটি খোলা রাখুন এবং দ্বিতীয় একটি টার্মিনাল থেকে নতুন লগইন পরীক্ষা করুন।
- **Docker UFW-কে পাশ কাটাতে পারে।** Docker container `-p` দিয়ে যে port প্রকাশ করে, UFW-তে তার কোনো rule না থাকলেও সেটি বাইরে থেকে খোলা থাকে। গোপন রাখতে চান এমন সার্ভিস শুধু `127.0.0.1`-এ প্রকাশ করুন। বিস্তারিত: [Docker](../docker.md)।
- বাইরে যাওয়া সংযোগে কোনো বিধিনিষেধ নেই। সার্ভারে কোনো প্রোগ্রাম আক্রান্ত হলে firewall সেটিকে বাইরে সংযোগ করা থেকে আটকায় না।
- SSH port সব ঠিকানার জন্য খোলা হয় এবং এতে কোনো rate limit থাকে না। পাসওয়ার্ড অনুমানের চেষ্টা ধীর করতে চাইলে আপনি নিজে `sudo ufw limit 22/tcp` দিয়ে rule-টি বদলে নিতে পারেন; পাশাপাশি [ssh-hardening](ssh-hardening.md) দিয়ে SSH আরও সুরক্ষিত করা উচিত।
- Protocol ছাড়া `--allow 8080` দিলে port-টি TCP ও UDP দুটোর জন্যই খুলে যায়। শুধু প্রয়োজনীয়টুকু খুলতে `/tcp` অথবা `/udp` যোগ করুন।
- Firewall IPv4 ও IPv6 দুটোতেই কাজ করে (UFW-এর ডিফল্ট আচরণ)।

## 10. সিস্টেমে যেসব পরিবর্তন হয়

- `ufw` প্যাকেজ না থাকলে ইনস্টল হয়।
- UFW-এর ডিফল্ট নীতি বদলে "বাইরে থেকে আসা বন্ধ, বাইরে যাওয়া খোলা" হয়ে যায়; আপনি আগে অন্য কিছু ঠিক করে রাখলেও।
- অনুমতির নতুন rule যোগ হয়। আগের rule-গুলো যেমন ছিল তেমনই থাকে।
- Firewall এখনই এবং প্রতিবার বুটের সময় চালু হয়।
- যেসব port-এর অনুমতির rule নেই, সেগুলোতে বাইরে থেকে আসা সংযোগ সঙ্গে সঙ্গে বন্ধ হয়ে যায়। আগে থেকে চালু থাকা সংযোগ, যেমন আপনার SSH সেশন, চলতে থাকে।

## 11. আগের অবস্থায় ফিরে যাওয়া (Rollback)

Firewall বন্ধ করুন। সব rule থেকে যায়, কিন্তু আর কার্যকর থাকে না:

```bash
sudo ufw disable
```

স্ক্রিপ্টের যোগ করা একটি rule মুছুন, যেমন HTTP:

```bash
sudo ufw delete allow 80/tcp
```

UFW-এর **সব** rule মুছে firewall বন্ধ করুন। এতে আপনার নিজের তৈরি rule-গুলোও মুছে যায়:

```bash
sudo ufw --force reset
```

UFW পুরোপুরি সরিয়ে ফেলুন:

```bash
sudo apt-get purge -y ufw
```

## 12. সমস্যা সমাধান

| সমস্যা | কারণ ও সমাধান |
| --- | --- |
| `This script must be run as root.` | কমান্ডটি `sudo` দিয়ে চালান। |
| `firewalld is active on this system.` | দুটি firewall manager একসাথে চালানো যাবে না। হয় firewalld-ই ব্যবহার করতে থাকুন, নয়তো `sudo systemctl disable --now firewalld` দিয়ে সেটি বন্ধ করে স্ক্রিপ্টটি আবার চালান। |
| `Could not detect the SSH port; assuming 22.` | SSH সার্ভার ইনস্টল নেই অথবা তার কনফিগারেশন পড়া যায়নি। SSH অন্য port ব্যবহার করলে `--ssh-port` দিয়ে সেটি জানিয়ে দিন। |
| SSH দিয়ে আর ঢুকতে পারছি না | আপনার hosting provider-এর web console (VNC বা serial console) দিয়ে লগইন করে আপনার আসল SSH port বসিয়ে `sudo ufw allow 22/tcp` চালান, অথবা `sudo ufw disable` চালান। |
| Firewall চালু করার পর আমার ওয়েবসাইট খুলছে না | Port 80 ও 443-এর অনুমতি দেওয়া নেই। `sudo ufw allow 80/tcp` ও `sudo ufw allow 443/tcp` চালান, অথবা `--web` দিয়ে স্ক্রিপ্টটি আবার চালান। |
| `ufw --force enable` চালালে `iptables` বা `ufw-init` সংক্রান্ত error দেখিয়ে ব্যর্থ হয় | UFW-এর যে firewall সুবিধা দরকার, kernel তা দিচ্ছে না। OpenVZ বা LXC-ভিত্তিক VPS-এ এটি প্রায়ই ঘটে; আপনার provider-কে জিজ্ঞেস করুন, অথবা provider-এর control panel-এর firewall ব্যবহার করুন। |
| UFW-এর তালিকায় না থাকা সত্ত্বেও Docker container-এর port খোলা | এটি Docker-এর স্বাভাবিক আচরণ; 9 নম্বর অংশ দেখুন। |

সাধারণ সমস্যাগুলোর সমাধান পাবেন [সমস্যা সমাধান](../troubleshooting.md) পাতায়।

## 13. টেস্টিং স্ট্যাটাস

| কী পরীক্ষা করা হয় | কীভাবে পরীক্ষা করা হয় |
| --- | --- |
| Shell syntax ও প্রচলিত ভুল | প্রতিটি push-এ CI-তে `shellcheck` চালিয়ে |
| অপশন যাচাই, অসমর্থিত OS শনাক্তকরণ, root যাচাই, `--dry-run`-এর আউটপুট | CI-তে `tests/smoke.sh` চালিয়ে |
| সত্যিকারের রান: rule যোগ হওয়া, firewall সক্রিয় হওয়া, এরপর `ufw disable` | CI-তে `tests/system.sh` চালিয়ে; GitHub-এর Ubuntu 22.04 ও 24.04 virtual machine-এ |
| Ubuntu 26.04 এবং Debian 12, 13-এ সত্যিকারের রান | স্বয়ংক্রিয়ভাবে পরীক্ষা করা হয় না; সেখানে শুধু `--dry-run` চলে (CI-এর container-গুলোতে firewall চালু করা যায় না) |
| চালু SSH সার্ভারে ভিন্ন SSH port শনাক্তকরণ | স্বয়ংক্রিয়ভাবে পরীক্ষা করা হয় না |

এই স্ক্রিপ্টের ওপর নির্ভর করার আগে production নয় এমন একটি সার্ভারে পরীক্ষা করে নিন।
