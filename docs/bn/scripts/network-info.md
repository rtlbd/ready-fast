# network-info

🌐 [English](../../en/scripts/network-info.md) | **বাংলা**

[← ডকুমেন্টেশনের মূল পাতা](../README.md)

## 1. পরিচিতি

`network-info` স্ক্রিপ্টটি আপনার সার্ভারের নেটওয়ার্ক কনফিগারেশনের একটি সংক্ষিপ্ত রিপোর্ট দেখায়: সার্ভারের নাম, IP address, default route, DNS server এবং কোন কোন port-এ প্রোগ্রাম সংযোগের অপেক্ষায় আছে। এটি শুধু তথ্য পড়ে, কখনো কিছু পরিবর্তন করে না; তাই যেকোনো সময় নিশ্চিন্তে চালানো যায়।

নতুন সার্ভার সেটআপের সময়, firewall কনফিগার করার আগে, অথবা "নেটওয়ার্ক কাজ করছে না" এমন অবস্থায় দ্রুত সঠিক তথ্য পেতে এটি ব্যবহার করুন। রিপোর্টটি কীভাবে পড়তে হয় তা জানতে [নেটওয়ার্কিং](../networking.md) গাইডটি দেখুন।

## 2. কী কাজ করে

- মেশিনের hostname দেখায়।
- প্রতিটি network interface, তার অবস্থা ও IP address-এর তালিকা দেখায়।
- IPv4 ও IPv6-এর default route (যে gateway দিয়ে সার্ভার ইন্টারনেটে পৌঁছায়) দেখায়।
- `/etc/resolv.conf` থেকে DNS server-গুলোর তালিকা দেখায়।
- যেসব TCP ও UDP port-এ প্রোগ্রাম সংযোগ গ্রহণ করে, সেগুলোর তালিকা দেখায়।
- `--public-ip` দিলে: বাইরের একটি সার্ভিসের কাছ থেকে সার্ভারের public IP address জেনে নেয়।
- `--check` দিলে: DNS নাম resolve হচ্ছে কি না এবং বাইরের দিকে HTTPS সংযোগ কাজ করছে কি না পরীক্ষা করে।

## 3. সমর্থিত অপারেটিং সিস্টেম

| ডিস্ট্রিবিউশন | ভার্সন |
| --- | --- |
| Ubuntu | 22.04, 24.04, 26.04 |
| Debian | 12, 13 |

এই স্ক্রিপ্টটি অপারেটিং সিস্টেম যাচাই করে না। `iproute2`-এর টুলগুলো আছে এমন অন্য Linux ডিস্ট্রিবিউশনেও এটি কাজ করার কথা, তবে পরীক্ষা করা হয়েছে শুধু টেবিলে উল্লেখ করা সিস্টেমগুলোতে। বিস্তারিত: [সমর্থিত অপারেটিং সিস্টেম](../supported-os.md)।

## 4. যা যা প্রয়োজন

- Root permission: **লাগে না**। তবে `sudo` দিয়ে চালালে listening port-এর তালিকায় প্রতিটি port-এর পেছনের প্রোগ্রামের নামও দেখা যায়।
- `iproute2` প্যাকেজের `ip` ও `ss` কমান্ড। এগুলো না থাকলে স্ক্রিপ্টটি ব্যর্থ না হয়ে রিপোর্টেই তা জানিয়ে দেয়।
- `curl`, শুধু `--public-ip` এবং `--check`-এর HTTPS পরীক্ষার জন্য।
- ready-fast ইনস্টল করা থাকতে হবে ([ইনস্টলেশন](../installation.md) দেখুন)।

## 5. ইনস্টলেশন কমান্ড

সাধারণ রিপোর্ট:

```bash
ready-fast run network-info
```

কোন port কোন প্রোগ্রাম ব্যবহার করছে সেটিসহ রিপোর্ট:

```bash
sudo ready-fast run network-info
```

Public IP address ও সংযোগ পরীক্ষাসহ রিপোর্ট:

```bash
ready-fast run network-info --public-ip --check
```

## 6. ধাপে ধাপে ব্যাখ্যা

স্ক্রিপ্টটি নিচের কমান্ডগুলো চালায় (এগুলো শুধু তথ্য পড়ে) এবং প্রতিটির আউটপুট একটি শিরোনামের নিচে দেখায়।

**Hostname**

```bash
hostname
```

**IP address**

```bash
ip -brief address show
```

প্রতিটি network interface-এর জন্য একটি করে লাইন: নাম, অবস্থা (`UP` অথবা `DOWN`) এবং address।

**Default route**

```bash
ip route show default
ip -6 route show default
```

`via`-এর পরের address-টিই gateway। এখানে কিছু না দেখালে বুঝতে হবে সার্ভার থেকে ইন্টারনেটে যাওয়ার কোনো পথ নেই।

**DNS server**

স্ক্রিপ্টটি `/etc/resolv.conf` ফাইলের `nameserver` লাইনগুলো পড়ে।

**Listening port**

```bash
ss -tuln
```

`-t` ও `-u` দিয়ে TCP ও UDP বেছে নেওয়া হয়, `-l` শুধু listening socket দেখায় এবং `-n` নামের বদলে সংখ্যা দেখায়। Root হিসেবে চালালে স্ক্রিপ্টটি `ss -tulnp` ব্যবহার করে, যাতে প্রোগ্রামের নামও যোগ হয়।

**Public IP address** (শুধু `--public-ip` দিলে)

```bash
curl -fsS --max-time 8 https://api.ipify.org
```

**সংযোগ পরীক্ষা** (শুধু `--check` দিলে)

```bash
getent hosts example.com
curl -fsS --max-time 8 -o /dev/null https://example.com
```

প্রথম লাইনটি DNS resolution পরীক্ষা করে। দ্বিতীয় লাইনটি পরীক্ষা করে সার্ভার ইন্টারনেটের দিকে HTTPS সংযোগ খুলতে পারছে কি না।

## 7. কমান্ড অপশন

| অপশন | অর্থ |
| --- | --- |
| `--public-ip` | Public IP address-ও দেখায়। এতে `https://api.ipify.org`-এ একটি request পাঠানো হয়। |
| `--check` | `example.com` ব্যবহার করে DNS resolution ও বাইরের দিকে HTTPS সংযোগও পরীক্ষা করে। |
| `--help` | সাহায্য-বার্তা দেখিয়ে বের হয়ে যায়। |

রিপোর্ট সম্পূর্ণ হলে exit status হয় 0। `--public-ip` অথবা `--check`-এর কোনো পরীক্ষা ব্যর্থ হলে হয় 1।

## 8. প্রত্যাশিত আউটপুট

ছোট একটি web server-এ `ready-fast run network-info --check` চালালে এই আউটপুট আসে। আপনার ক্ষেত্রে নাম ও address ভিন্ন হবে:

```text

== Hostname ==
web-01

== IP addresses ==
lo               UNKNOWN        127.0.0.1/8 ::1/128
eth0             UP             203.0.113.10/24

== Default routes ==
default via 203.0.113.1 dev eth0

== DNS servers ==
1.1.1.1
8.8.8.8

== Listening ports ==
Netid State  Recv-Q Send-Q Local Address:Port Peer Address:Port
tcp   LISTEN 0      128          0.0.0.0:22        0.0.0.0:*
tcp   LISTEN 0      128             [::]:22           [::]:*

== Connectivity check ==
DNS resolution (example.com): OK
Outbound HTTPS (https://example.com): OK

[OK] Network report complete.
```

কোনো পরীক্ষা ব্যর্থ হলে সেই লাইনের শেষে `FAILED` লেখা থাকে এবং রিপোর্টের শেষে আসে:

```text
[ERROR] At least one network check failed.
```

## 9. নিরাপত্তা বিষয়ক সতর্কতা

- স্ক্রিপ্টটি শুধু তথ্য পড়ে। এটি interface, route, DNS সেটিং বা firewall rule কিছুই বদলায় না।
- রিপোর্টে IP address ও খোলা port-এর তথ্য থাকে। কোনো পাবলিক ফোরাম বা issue-তে আউটপুট পোস্ট করার আগে সেগুলো মুছে দিন অথবা ঢেকে দিন।
- `--public-ip` একটি third-party সার্ভিসের (`api.ipify.org`) সাথে যোগাযোগ করে। ওই সার্ভিস আপনার সার্ভারের public IP address দেখতে পায়। এটি মেনে নিতে না পারলে অপশনটি ব্যবহার করবেন না।
- `--check` যোগাযোগ করে `example.com`-এর সাথে। সংযোগটুকু ছাড়া আপনার সার্ভার সম্পর্কে আর কোনো তথ্য পাঠানো হয় না।
- এই দুটি অপশন না দিলে স্ক্রিপ্টটি কোনো নেটওয়ার্ক সংযোগই তৈরি করে না।

## 10. সিস্টেমে যেসব পরিবর্তন হয়

কোনো পরিবর্তন হয় না। কোনো ফাইল লেখা হয় না, কোনো সেটিং বদলায় না। শুধু `--public-ip` বা `--check` দিলে বাইরের দিকে স্বল্প সময়ের সংযোগ তৈরি হয়।

## 11. আগের অবস্থায় ফিরে যাওয়া (Rollback)

ফিরিয়ে নেওয়ার মতো কিছু নেই, কারণ স্ক্রিপ্টটি সিস্টেমে কোনো পরিবর্তন করে না।

## 12. সমস্যা সমাধান

| সমস্যা | কারণ ও সমাধান |
| --- | --- |
| `(the 'ip' command is missing; install the iproute2 package)` | `sudo apt-get install -y iproute2` দিয়ে টুলগুলো ইনস্টল করে স্ক্রিপ্টটি আবার চালান। |
| DNS server হিসেবে `127.0.0.53` দেখাচ্ছে | সিস্টেমটি `systemd-resolved` ব্যবহার করছে; এটি এই local address-এ উত্তর দেয় এবং আসল DNS server-এর কাছে প্রশ্ন পাঠিয়ে দেয়। আসল server-গুলো দেখতে `resolvectl status` চালান। |
| `(no default route)` | সার্ভারের কোনো gateway নেই, তাই এটি ইন্টারনেটে পৌঁছাতে পারছে না। আপনার provider-এর control panel-এ অথবা `/etc/netplan/` (Ubuntu) বা `/etc/network/interfaces` (Debian)-এ নেটওয়ার্ক কনফিগারেশন পরীক্ষা করুন। |
| `DNS resolution (example.com): FAILED` | DNS server-গুলোতে পৌঁছানো যাচ্ছে না অথবা সেগুলো ভুল। রিপোর্টের "DNS servers" অংশটি মিলিয়ে দেখুন। |
| DNS `OK`, অথচ `Outbound HTTPS (https://example.com): FAILED` | Port 443-এ বাইরের দিকে সংযোগ বন্ধ করা আছে; সাধারণত provider-এর firewall অথবা বাধ্যতামূলক proxy-র কারণে এমন হয়। |
| `FAILED (could not reach https://api.ipify.org)` | আপনার সার্ভার থেকে সার্ভিসটিতে পৌঁছানো যাচ্ছে না। রিপোর্টের বাকি অংশ ঠিকই আছে। |
| Port-এর তালিকায় প্রোগ্রামের নাম নেই | স্ক্রিপ্টটি `sudo` দিয়ে চালান। |

সাধারণ সমস্যাগুলোর সমাধান পাবেন [সমস্যা সমাধান](../troubleshooting.md) পাতায়।

## 13. টেস্টিং স্ট্যাটাস

| কী পরীক্ষা করা হয় | কীভাবে পরীক্ষা করা হয় |
| --- | --- |
| Shell syntax ও প্রচলিত ভুল | প্রতিটি push-এ CI-তে `shellcheck` চালিয়ে |
| অপশন যাচাই ও একটি সাধারণ রান | CI-তে `tests/smoke.sh` চালিয়ে; GitHub-এর একটি Ubuntu virtual machine-এ এবং Ubuntu 22.04, 24.04, 26.04 ও Debian 12, 13-এর `amd64` container-এর ভেতরে |
| সচল ইন্টারনেট সংযোগে `--public-ip` ও `--check` | স্বয়ংক্রিয়ভাবে পরীক্ষা করা হয় না |
| `arm64` | পরীক্ষা করা হয়নি |
