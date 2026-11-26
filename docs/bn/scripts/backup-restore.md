# backup-restore

🌐 [English](../../en/scripts/backup-restore.md) | **বাংলা**

[← ডকুমেন্টেশনের মূল পাতা](../README.md)

## 1. পরিচিতি

`backup-restore` স্ক্রিপ্টটি [backup-create](backup-create.md) দিয়ে তৈরি archive নিয়ে কাজ করে। এটি দিয়ে archive অক্ষত আছে কি না যাচাই করা যায়, ভেতরে কী আছে তা দেখা যায় এবং ফাইলগুলো আপনার পছন্দের ডিরেক্টরিতে বের করে (extract) আনা যায়।

Restore করার নিরাপদ উপায় হলো প্রথমে একটি ফাঁকা পরীক্ষামূলক ডিরেক্টরিতে extract করা, ফাইলগুলো দেখে নেওয়া এবং শুধু দরকারি ফাইলটুকু কপি করে ফিরিয়ে নেওয়া। চালু সিস্টেমের ওপর সরাসরি restore করাও সম্ভব, কিন্তু তাতে ফাইল overwrite হয়ে যায় এবং সেটি আর ফেরানো যায় না। পূর্ণাঙ্গ নিয়মের জন্য [ব্যাকআপ](../backup.md) গাইডটি দেখুন।

## 2. কী কাজ করে

- Archive আছে কি না এবং পড়া যাচ্ছে কি না তা যাচাই করে।
- Archive-এর পাশে `.sha256` ফাইল থাকলে SHA-256 checksum মিলিয়ে দেখে। Checksum না মিললে স্ক্রিপ্টটি থেমে যায় এবং কিছুই extract করে না।
- `--list` দিলে: archive-এর সব ফাইলের path দেখিয়ে বের হয়ে যায়।
- `--target` দিলে: নিশ্চিতকরণ চায়, দরকার হলে target ডিরেক্টরি তৈরি করে এবং archive-টি তার ভেতরে extract করে।

মূল সিস্টেমে ফাইলের যে path ছিল, target ডিরেক্টরির নিচে সেই path-ই বজায় থাকে। যে ফাইলটি ছিল `/etc/hostname`, সেটি extract হয় `<target>/etc/hostname`-এ।

## 3. সমর্থিত অপারেটিং সিস্টেম

| ডিস্ট্রিবিউশন | ভার্সন |
| --- | --- |
| Ubuntu | 22.04, 24.04, 26.04 |
| Debian | 12, 13 |

এই স্ক্রিপ্টটি অপারেটিং সিস্টেম যাচাই করে না। GNU `tar` আছে এমন অন্য Linux ডিস্ট্রিবিউশনেও এটি কাজ করার কথা, তবে পরীক্ষা করা হয়েছে শুধু টেবিলে উল্লেখ করা সিস্টেমগুলোতে। বিস্তারিত: [সমর্থিত অপারেটিং সিস্টেম](../supported-os.md)।

## 4. যা যা প্রয়োজন

- Root permission: **পরিস্থিতির ওপর নির্ভর করে**। আপনার ব্যবহারকারী archive পড়তে না পারলে (`/var/backups/ready-fast`-এর archive-গুলোর মালিক root), target-এ লিখতে না পারলে, অথবা ফাইলের মূল মালিকানা ফিরিয়ে আনতে হলে `sudo` লাগবে।
- Uncompressed ফাইলগুলোর জন্য target-এ যথেষ্ট খালি জায়গা।
- প্রচলিত টুল `tar`, `gzip` ও `sha256sum`।
- ready-fast ইনস্টল করা থাকতে হবে ([ইনস্টলেশন](../installation.md) দেখুন)।

## 5. ইনস্টলেশন কমান্ড

একটি archive যাচাই করে তার ভেতরের তালিকা দেখুন। এতে কিছুই extract হয় না:

```bash
sudo ready-fast run backup-restore --file /var/backups/ready-fast/etc-20261126-210300.tar.gz --list
```

প্রস্তাবিত পদ্ধতি: আলাদা একটি পরীক্ষামূলক ডিরেক্টরিতে extract করুন:

```bash
sudo ready-fast run backup-restore --file /var/backups/ready-fast/etc-20261126-210300.tar.gz --target /tmp/restore-test
```

এরপর শুধু দরকারি ফাইলটি কপি করে ফিরিয়ে নিন, যেমন:

```bash
sudo cp -a /tmp/restore-test/etc/hostname /etc/hostname
```

সবকিছু তার মূল জায়গায় restore করুন। **এতে বর্তমান ফাইলগুলো overwrite হয়ে যায়:**

```bash
sudo ready-fast run backup-restore --file /var/backups/ready-fast/etc-20261126-210300.tar.gz --target /
```

Extract করার আগে স্ক্রিপ্টটি জিজ্ঞেস করে: `Extract the archive? [y/N]:`।

## 6. ধাপে ধাপে ব্যাখ্যা

**ধাপ 1 — checksum যাচাই।** একই ডিরেক্টরিতে archive-এর নামের শেষে `.sha256` যোগ করা কোনো ফাইল থাকলে স্ক্রিপ্টটি এই কমান্ড চালায়:

```bash
sha256sum --check --status etc-20261126-210300.tar.gz.sha256
```

এতে archive-এর checksum নতুন করে হিসাব করে সংরক্ষিত checksum-এর সাথে মেলানো হয়। না মিললে বুঝতে হবে ব্যাকআপের পর archive-টি নষ্ট হয়েছে বা বদলে গেছে; তখন স্ক্রিপ্টটি থেমে যায়। `.sha256` ফাইল না থাকলে একটি সতর্কবার্তা দেখিয়ে স্ক্রিপ্টটি এগিয়ে যায়।

**ধাপ 2 — তালিকা দেখানো** (শুধু `--list` দিলে)।

```bash
tar --list --gzip --file /var/backups/ready-fast/etc-20261126-210300.tar.gz
```

**ধাপ 3 — নিশ্চিতকরণ।** স্ক্রিপ্টটি archive ও target দেখায়, একই path-এর ফাইল overwrite হয়ে যাবে বলে সতর্ক করে এবং আপনার উত্তরের অপেক্ষা করে।

**ধাপ 4 — extract করা** (শুধু `--target` দিলে)।

```bash
install -d /tmp/restore-test
tar --extract --gzip --preserve-permissions --file /var/backups/ready-fast/etc-20261126-210300.tar.gz --directory /tmp/restore-test
```

প্রথম লাইনটি target ডিরেক্টরি না থাকলে তৈরি করে। দ্বিতীয় লাইনটি সব ফাইল তার নিচে extract করে এবং সেগুলোর permission ফিরিয়ে আনে। Root হিসেবে চালালে ফাইলের মূল মালিকানাও ফিরে আসে।

## 7. কমান্ড অপশন

| অপশন | অর্থ |
| --- | --- |
| `--file <archive>` | যে `.tar.gz` archive ব্যবহার করা হবে। এটি আবশ্যক। |
| `--list` | Archive-এর ভেতরের তালিকাটুকুই শুধু দেখায়; কিছুই extract করে না। `--target`-এর সাথে একসাথে ব্যবহার করা যায় না। |
| `--target <dir>` | যে ডিরেক্টরিতে extract করা হবে। `--list` ব্যবহার না করলে এটি আবশ্যক। |
| `--dry-run` | কী কী করা হবে তা দেখায়, কিন্তু কিছুই পরিবর্তন করে না। Checksum তখনো যাচাই করা হয়। |
| `--yes` | নিশ্চিতকরণের প্রশ্ন জিজ্ঞেস করে না। |
| `--help` | সাহায্য-বার্তা দেখিয়ে বের হয়ে যায়। |

## 8. প্রত্যাশিত আউটপুট

Archive-এর তালিকা দেখলে:

```text
[OK] Checksum verified: etc-20261126-210300.tar.gz
etc/
etc/hostname
etc/hosts
...
```

পরীক্ষামূলক ডিরেক্টরিতে extract করলে:

```text
[OK] Checksum verified: etc-20261126-210300.tar.gz
[INFO] Archive: /var/backups/ready-fast/etc-20261126-210300.tar.gz
[INFO] Target:  /tmp/restore-test
[WARN] Existing files below /tmp/restore-test with the same paths will be overwritten.
Extract the archive? [y/N]: y
[OK] Restore complete: files were extracted into /tmp/restore-test
```

Archive নষ্ট হয়ে থাকলে:

```text
[ERROR] Checksum mismatch for etc-20261126-210300.tar.gz. The archive is damaged or was modified; nothing was extracted.
```

## 9. নিরাপত্তা বিষয়ক সতর্কতা

- **Restore করলে ফাইল overwrite হয়।** Archive-এর কোনো ফাইলের সাথে target-এর যে ফাইলের path মিলে যায়, সেটি বদলে যায়। এটি আর ফেরানো যায় না। তাই আলাদা target ডিরেক্টরি ব্যবহার করাই ভালো।
- **`--target /` ব্যবহারে খুব সাবধান থাকুন।** চালু সিস্টেমের ওপর পুরোনো `/etc` restore করলে পুরোনো পাসওয়ার্ড, SSH সেটিং, firewall rule ও নেটওয়ার্ক কনফিগারেশন ফিরে আসতে পারে এবং আপনি সার্ভারের বাইরে আটকে পড়তে পারেন। এক সার্ভারের `/etc` কখনোই অন্য সার্ভারে restore করবেন না।
- শুধু সেই archive-ই restore করুন, যা আপনি নিজে তৈরি করেছেন অথবা যা আপনার বিশ্বস্ত উৎস থেকে এসেছে। Archive-এ যেকোনো ফাইল থাকতে পারে; এমন প্রোগ্রাম ও কনফিগারেশনও, যা restore-এর পর root-এর ক্ষমতায় চলে।
- Checksum দুর্ঘটনাবশত নষ্ট হওয়া থেকে সুরক্ষা দেয়। Archive-টি কে তৈরি করেছে, তা এটি প্রমাণ করে না: যে archive বদলাতে পারে, সে `.sha256` ফাইলও বদলাতে পারে।
- Restore করা ফাইল এনক্রিপ্ট করা থাকে না। `/tmp/restore-test`-এর মতো পরীক্ষামূলক ডিরেক্টরিতেও ব্যাকআপের সেই একই গোপন তথ্য থাকে; কাজ শেষে সেটি মুছে ফেলুন।

## 10. সিস্টেমে যেসব পরিবর্তন হয়

- `--list` অথবা `--dry-run` দিলে: কোনো পরিবর্তন হয় না।
- `--target` দিলে: target ডিরেক্টরি না থাকলে তৈরি হয় এবং archive-এর ফাইলগুলো তার নিচে লেখা হয়। একই path-এর আগের ফাইল overwrite হয়ে যায়।
- Target-এ থাকা যেসব ফাইল archive-এ নেই, সেগুলোতে হাত দেওয়া হয় না। Restore কিছুই মুছে ফেলে না, তাই এতে target হুবহু ব্যাকআপের মতো হয়ে যায় না।

## 11. আগের অবস্থায় ফিরে যাওয়া (Rollback)

Restore নিজে থেকে ফেরানো যায় না; তাই বর্তমান ফাইলের ওপর restore করার আগেই প্রস্তুতি নিন। প্রথমে বর্তমান অবস্থার একটি নতুন ব্যাকআপ নিয়ে রাখুন:

```bash
sudo ready-fast run backup-create --source /etc --name etc-before-restore
```

Restore-এর কারণে কোনো সমস্যা হলে ওই archive-টি একই নিয়মে restore করুন।

পরীক্ষামূলক ডিরেক্টরিতে extract করে থাকলে ডিরেক্টরিটি মুছে ফেললেই আগের অবস্থায় ফিরে যাওয়া হয়:

```bash
sudo rm -rf /tmp/restore-test
```

## 12. সমস্যা সমাধান

| সমস্যা | কারণ ও সমাধান |
| --- | --- |
| `Archive not found` | `--file`-এ দেওয়া path মিলিয়ে দেখুন। `sudo ls -lh /var/backups/ready-fast` দিয়ে কোন কোন archive আছে তা দেখে নিন। |
| `Archive is not readable` | কমান্ডটি `sudo` দিয়ে চালান। |
| `Checksum mismatch` | Archive-টি নষ্ট হয়েছে অথবা বদলে গেছে। এই ব্যাকআপের অন্য কোনো কপি অথবা আগের কোনো archive ব্যবহার করুন। এই ফাইল থেকে restore করার চেষ্টা করবেন না। |
| `No checksum file found` | Archive-এর সাথে `.sha256` ফাইলটি কপি করা হয়নি। Restore চলতে থাকে, কিন্তু archive যাচাই করা হয় না। ফাইল দুটি সবসময় একসাথে রাখুন। |
| `--target <dir> is required` | একটি ডিরেক্টরিসহ `--target` যোগ করুন, অথবা শুধু ভেতরের তালিকা দেখতে চাইলে `--list` ব্যবহার করুন। |
| `Confirmation is required but no terminal is attached.` | কমান্ডটি টার্মিনাল ছাড়া চলছে, যেমন কোনো স্ক্রিপ্ট থেকে। আপনি নিশ্চিত হলে `--yes` যোগ করুন। |
| `tar could not extract` | Error-টির ওপরে থাকা `tar`-এর বার্তাগুলো পড়ুন। প্রচলিত কারণ হলো target-এর ডিস্ক ভরে যাওয়া এবং লেখার permission না থাকা। কিছু ফাইল ইতিমধ্যে extract হয়ে গিয়ে থাকতে পারে। |
| Restore করা ফাইলের মালিক ভুল ব্যবহারকারী | Archive-টি root ছাড়া extract করা হয়েছে। মূল মালিকানা ফিরিয়ে আনতে `sudo` দিয়ে restore চালান। |

সাধারণ সমস্যাগুলোর সমাধান পাবেন [সমস্যা সমাধান](../troubleshooting.md) পাতায়।

## 13. টেস্টিং স্ট্যাটাস

| কী পরীক্ষা করা হয় | কীভাবে পরীক্ষা করা হয় |
| --- | --- |
| Shell syntax ও প্রচলিত ভুল | প্রতিটি push-এ CI-তে `shellcheck` চালিয়ে |
| অপশন যাচাই, checksum যাচাই, `--list`, `--dry-run`, টার্মিনাল ছাড়া নিশ্চিতকরণ, extract করা, ফাইলের বিষয়বস্তু ও permission হুবহু মিলে যাওয়া, নষ্ট archive প্রত্যাখ্যান | CI-তে `tests/smoke.sh` চালিয়ে; GitHub-এর একটি Ubuntu virtual machine-এ এবং Ubuntu 22.04, 24.04, 26.04 ও Debian 12, 13-এর `amd64` container-এর ভেতরে |
| চালু সিস্টেমে `/`-এ restore করা | স্বয়ংক্রিয়ভাবে পরীক্ষা করা হয় না |
| `arm64` | পরীক্ষা করা হয়নি |
