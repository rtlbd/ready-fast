# backup-create

🌐 [English](../../en/scripts/backup-create.md) | **বাংলা**

[← ডকুমেন্টেশনের মূল পাতা](../README.md)

## 1. পরিচিতি

`backup-create` স্ক্রিপ্টটি আপনার বেছে নেওয়া ফাইল ও ডিরেক্টরিগুলোকে একটি compressed archive-এ (`.tar.gz` ফাইল) গুছিয়ে রাখে এবং তার পাশে একটি checksum ফাইল লেখে। Archive-টি পরে কোনোভাবে নষ্ট হয়েছে কি না, তা এই checksum দিয়ে ধরা যায়।

কনফিগারেশন বদলানোর আগে, আপগ্রেডের আগে অথবা নির্দিষ্ট সময় পরপর নিয়মিতভাবে এটি ব্যবহার করুন। ফাইলগুলো ফিরিয়ে আনে এর জোড়া স্ক্রিপ্ট [backup-restore](backup-restore.md)। ব্যাকআপের পূর্ণাঙ্গ নিয়মের জন্য [ব্যাকআপ](../backup.md) গাইডটি দেখুন।

## 2. কী কাজ করে

- প্রতিটি source আছে কি না এবং পড়া যাচ্ছে কি না তা যাচাই করে।
- Destination ডিরেক্টরি না থাকলে তৈরি করে।
- `<dest>/<name>-YYYYMMDD-HHMMSS.tar.gz` নামে archive তৈরি করে। নামের তারিখ ও সময় নেওয়া হয় সার্ভারের ঘড়ি থেকে।
- Archive-এর SHA-256 checksum একই নামের শেষে `.sha256` যোগ করা একটি ফাইলে লেখে।
- `--keep` দিলে: একই নামের পুরোনো archive মুছে ফেলে, যাতে ডিস্ক ভরে না যায়।

Source ফাইলগুলো শুধু পড়া হয়; সেগুলো কখনো বদলানো বা মুছে ফেলা হয় না। ফাইলের permission, মালিকানা (owner) ও symbolic link archive-এ সংরক্ষিত থাকে।

## 3. সমর্থিত অপারেটিং সিস্টেম

| ডিস্ট্রিবিউশন | ভার্সন |
| --- | --- |
| Ubuntu | 22.04, 24.04, 26.04 |
| Debian | 12, 13 |

এই স্ক্রিপ্টটি অপারেটিং সিস্টেম যাচাই করে না। GNU `tar` আছে এমন অন্য Linux ডিস্ট্রিবিউশনেও এটি কাজ করার কথা, তবে পরীক্ষা করা হয়েছে শুধু টেবিলে উল্লেখ করা সিস্টেমগুলোতে। বিস্তারিত: [সমর্থিত অপারেটিং সিস্টেম](../supported-os.md)।

## 4. যা যা প্রয়োজন

- Root permission: **পরিস্থিতির ওপর নির্ভর করে**। আপনার ব্যবহারকারী source পড়তে না পারলে (যেমন `/etc`) অথবা destination-এ লিখতে না পারলে `sudo` লাগবে। ডিফল্ট destination `/var/backups/ready-fast`-এর জন্য root লাগে।
- Compressed archive-টির জন্য destination-এ যথেষ্ট খালি জায়গা।
- প্রচলিত টুল `tar`, `gzip` ও `sha256sum`।
- ready-fast ইনস্টল করা থাকতে হবে ([ইনস্টলেশন](../installation.md) দেখুন)।

## 5. ইনস্টলেশন কমান্ড

Preview। এতে কোন কোন কমান্ড চলবে তা দেখানো হয়, কিন্তু কিছুই তৈরি হয় না:

```bash
sudo ready-fast run backup-create --source /etc --name etc --dry-run
```

`/etc`-এ থাকা সিস্টেম কনফিগারেশনের ব্যাকআপ নিন:

```bash
sudo ready-fast run backup-create --source /etc --name etc
```

দুটি ডিরেক্টরির ব্যাকআপ একটি archive-এ নিন এবং `web` নামের শুধু সবচেয়ে নতুন 7টি archive রাখুন:

```bash
sudo ready-fast run backup-create --source /etc --source /var/www --name web --keep 7
```

`/mnt/backup`-এ mount করা অন্য একটি ডিস্কে ব্যাকআপ নিন:

```bash
sudo ready-fast run backup-create --source /home/deploy/app --dest /mnt/backup --name app
```

স্ক্রিপ্টটি নিশ্চিতকরণের প্রশ্ন জিজ্ঞেস করে না, কারণ ব্যাকআপ তৈরি করলে আপনার ডেটায় কোনো পরিবর্তন হয় না। তবে `--keep` ব্যবহারে সাবধান থাকুন: পুরোনো archive-গুলো কোনো প্রশ্ন ছাড়াই মুছে ফেলা হয়।

## 6. ধাপে ধাপে ব্যাখ্যা

**ধাপ 1 — source যাচাই।** প্রতিটি `--source` path-কে তার পূর্ণ absolute path-এ রূপান্তর করা হয়। কোনো source না থাকলে, পড়া না গেলে অথবা সেটি `/` হলে স্ক্রিপ্টটি থেমে যায় (পুরো root filesystem-এর ব্যাকআপ নেওয়ার সুবিধা নেই)।

**ধাপ 2 — destination প্রস্তুত করা।** Destination ডিরেক্টরি না থাকলে সেটি এমনভাবে তৈরি করা হয়, যাতে শুধু এর মালিকই সেটি খুলতে পারেন (permission `0700`)। আগে থেকে থাকা ডিরেক্টরির permission অপরিবর্তিত থাকে।

**ধাপ 3 — archive তৈরি।** `/etc`-এর উদাহরণটির ক্ষেত্রে স্ক্রিপ্টটি এ রকম একটি কমান্ড চালায়:

```bash
tar --create --gzip --file /var/backups/ready-fast/etc-20261126-210300.tar.gz --directory / --no-wildcards --anchored --exclude var/backups/ready-fast etc
```

`--create --gzip --file` একটি compressed archive লেখে। `--directory /`-এর সাথে `etc` path দেওয়ায় ফাইলগুলো `/`-এর সাপেক্ষে path দিয়ে সংরক্ষিত হয় (যেমন `etc/hostname`), ফলে সেগুলো যেকোনো জায়গায় restore করা যায়। `--exclude var/backups/ready-fast` অংশটি destination ডিরেক্টরিটিকেই বাদ দেয়; তাই destination কোনো source-এর ভেতরে পড়লেও archive-এ কখনো পুরোনো ব্যাকআপ ঢুকে যায় না। Archive-টি এমনভাবে তৈরি হয়, যাতে শুধু এর মালিকই পড়তে পারেন (permission `0600`), কারণ ব্যাকআপে প্রায়ই পাসওয়ার্ড ও key থাকে।

**ধাপ 4 — checksum লেখা।**

```bash
sha256sum etc-20261126-210300.tar.gz
```

ফলাফলটি একই ডিরেক্টরিতে `etc-20261126-210300.tar.gz.sha256` নামে সংরক্ষণ করা হয়।

**ধাপ 5 — পুরোনো ব্যাকআপ ছাঁটাই (retention)** (শুধু `--keep` দিলে)। Destination-এ যেসব archive-এর নাম হুবহু `<name>-YYYYMMDD-HHMMSS.tar.gz` ধরনের, স্ক্রিপ্টটি সেগুলোর তালিকা করে, সবচেয়ে নতুনগুলো রেখে বাকিগুলো তাদের `.sha256` ফাইলসহ মুছে ফেলে। অন্য নামের archive-এ কখনো হাত দেওয়া হয় না।

Archive তৈরি ব্যর্থ হলে অসম্পূর্ণ ফাইলটি মুছে ফেলা হয়; তাই ব্যর্থ রানের পর কখনো ত্রুটিপূর্ণ ব্যাকআপ পড়ে থাকে না।

## 7. কমান্ড অপশন

| অপশন | অর্থ |
| --- | --- |
| `--source <path>` | যে ফাইল বা ডিরেক্টরির ব্যাকআপ নিতে হবে। এটি আবশ্যক। একাধিকবার দেওয়া যায়। |
| `--dest <dir>` | যে ডিরেক্টরিতে archive রাখা হবে। ডিফল্ট: `/var/backups/ready-fast`। |
| `--name <label>` | Archive-এর নামের প্রথম অংশ। অক্ষর, সংখ্যা, dot, dash ও underscore ব্যবহার করা যায়। ডিফল্ট: `backup`। |
| `--keep <count>` | ব্যাকআপ সফল হওয়ার পর destination-এ এই নামের শুধু সবচেয়ে নতুন `<count>`টি archive রেখে পুরোনোগুলো মুছে ফেলে। ডিফল্ট: 0, অর্থাৎ সবই রেখে দেওয়া হয়। |
| `--dry-run` | কী কী করা হবে তা দেখায়, কিন্তু কিছুই পরিবর্তন করে না। |
| `--help` | সাহায্য-বার্তা দেখিয়ে বের হয়ে যায়। |

## 8. প্রত্যাশিত আউটপুট

`sudo ready-fast run backup-create --source /etc --name etc --keep 7` চালালে এই আউটপুট আসে:

```text
[INFO] Sources: /etc
[INFO] Archive: /var/backups/ready-fast/etc-20261126-210300.tar.gz
[OK] Backup created: /var/backups/ready-fast/etc-20261126-210300.tar.gz (1.2M)
[OK] Checksum file:  /var/backups/ready-fast/etc-20261126-210300.tar.gz.sha256
[INFO] Retention: 1 archive(s) named 'etc' present, nothing to remove (keep 7).
```

7টির বেশি archive থাকলে মুছে ফেলা প্রতিটি archive-এর কথা জানানো হয়:

```text
[INFO] Removing old backup: /var/backups/ready-fast/etc-20261119-020000.tar.gz
```

## 9. নিরাপত্তা বিষয়ক সতর্কতা

- **Archive এনক্রিপ্ট করা থাকে না।** যে-ই archive পড়তে পারবে, সে-ই এর ভেতরের সবকিছু পড়তে পারবে; password hash, private key ও database-এর credential-সহ। স্ক্রিপ্টটি archive-টিকে শুধু মালিকের জন্য সীমিত রাখে, কিন্তু এর কপিগুলো সুরক্ষিত রাখার দায়িত্ব আপনার।
- **একই সার্ভারে রাখা ব্যাকআপ যথেষ্ট নয়।** ডিস্ক নষ্ট হলে বা সার্ভার মুছে গেলে ব্যাকআপও তার সাথে হারিয়ে যাবে। Archive-গুলো অন্য কোনো মেশিনে বা storage সার্ভিসে কপি করে রাখুন; বিস্তারিত [ব্যাকআপ](../backup.md) গাইডে আছে।
- `--keep` পুরোনো archive-গুলো চিরতরে এবং কোনো নিশ্চিতকরণ ছাড়াই মুছে ফেলে। যে ব্যাকআপ কোনোভাবেই মুছে যাওয়া চলবে না, তার জন্য আলাদা `--name` ব্যবহার করুন।
- চালু থাকা database-এর (MySQL, PostgreSQL, MongoDB ইত্যাদি) ডেটা ফাইল কপি করে নিরাপদে ব্যাকআপ নেওয়া যায় না। আগে database-এর নিজস্ব টুল দিয়ে একটি dump তৈরি করুন, তারপর সেই dump ফাইলের ব্যাকআপ নিন।
- আপনি যে path দেবেন, স্ক্রিপ্টটি সেটিই অনুসরণ করবে। `sudo` দিয়ে চালানোর সময় `--source` ও `--dest` দুবার মিলিয়ে নিন।

## 10. সিস্টেমে যেসব পরিবর্তন হয়

- Destination ডিরেক্টরিতে একটি নতুন archive ও একটি নতুন `.sha256` ফাইল তৈরি হয়।
- Destination ডিরেক্টরি না থাকলে তৈরি হয়।
- `--keep` দিলে: একই নামের পুরোনো archive ও সেগুলোর `.sha256` ফাইল মুছে যায়।
- Destination-এ ডিস্কের জায়গা খরচ হয়। বড় ডিরেক্টরি পড়ার সময় ব্যাকআপ চলাকালে ডিস্কের ওপর চাপ পড়ে।

## 11. আগের অবস্থায় ফিরে যাওয়া (Rollback)

ব্যাকআপ নিলে সিস্টেমে কোনো পরিবর্তন হয় না, তাই ফিরিয়ে নেওয়ার মতো কিছু নেই। দরকার নেই এমন কোনো archive সরাতে চাইলে সেটিকে তার checksum ফাইলসহ মুছে ফেলুন:

```bash
sudo rm -f /var/backups/ready-fast/etc-20261126-210300.tar.gz /var/backups/ready-fast/etc-20261126-210300.tar.gz.sha256
```

`--keep`-এর কারণে মুছে যাওয়া archive আর ফিরিয়ে আনা যায় না।

## 12. সমস্যা সমাধান

| সমস্যা | কারণ ও সমাধান |
| --- | --- |
| `At least one --source <path> is required.` | যে ফাইল বা ডিরেক্টরির ব্যাকআপ নিতে চান, সেটি `--source` দিয়ে যোগ করুন। |
| `Source does not exist` | Path-এ টাইপের কোনো ভুল আছে কি না দেখুন। |
| `Source is not readable` অথবা `Destination is not writable` | কমান্ডটি `sudo` দিয়ে চালান। |
| `tar failed with status 2. No backup was created.` | Error-টির ওপরে থাকা `tar`-এর বার্তাগুলো পড়ুন। সবচেয়ে প্রচলিত কারণ হলো destination-এর ডিস্ক ভরে যাওয়া (`df -h` দিয়ে দেখুন) এবং source-এর ভেতরে পড়া যায় না এমন ফাইল থাকা। |
| `Some files changed while they were being read.` | ব্যাকআপ চলার সময় কোনো প্রোগ্রাম ফাইলগুলোতে লিখছিল। Archive তৈরি হয়েছে, তবে ওই ফাইলগুলো অসম্পূর্ণ থাকতে পারে। আগে প্রোগ্রামটি বন্ধ করুন অথবা যখন কাজের চাপ কম থাকে তখন ব্যাকআপ নিন। Database-এর ক্ষেত্রে dump-এর ব্যাকআপ নিন। |
| `already exists. Wait one second and try again.` | একই সেকেন্ডের মধ্যে একই নামের দুটি ব্যাকআপ শুরু করা হয়েছে। কমান্ডটি আবার চালান। |
| `Invalid --name value` | নামে শুধু অক্ষর, সংখ্যা, dot, dash ও underscore ব্যবহার করুন। |
| ব্যাকআপে ডিস্ক ভরে যাচ্ছে | `--keep` ব্যবহার করুন এবং (root হিসেবে) `ls -lh /var/backups/ready-fast` দিয়ে পুরোনো archive-গুলো দেখে নিন। |

সাধারণ সমস্যাগুলোর সমাধান পাবেন [সমস্যা সমাধান](../troubleshooting.md) পাতায়।

## 13. টেস্টিং স্ট্যাটাস

| কী পরীক্ষা করা হয় | কীভাবে পরীক্ষা করা হয় |
| --- | --- |
| Shell syntax ও প্রচলিত ভুল | প্রতিটি push-এ CI-তে `shellcheck` চালিয়ে |
| অপশন যাচাই, `--dry-run`, archive ও checksum তৈরি, archive-এর permission, destination বাদ পড়া, `--keep` দিয়ে ছাঁটাই, restore করে ফাইল মিলিয়ে দেখা | CI-তে `tests/smoke.sh` চালিয়ে; GitHub-এর একটি Ubuntu virtual machine-এ এবং Ubuntu 22.04, 24.04, 26.04 ও Debian 12, 13-এর `amd64` container-এর ভেতরে |
| খুব বড় ডিরেক্টরি, বিশেষ ধরনের ফাইল (device, socket), ভরা ডিস্ক | স্বয়ংক্রিয়ভাবে পরীক্ষা করা হয় না |
| `arm64` | পরীক্ষা করা হয়নি |

Restore সফল না হওয়া পর্যন্ত কোনো ব্যাকআপকেই নির্ভরযোগ্য বলা যায় না। [backup-restore](backup-restore.md) দিয়ে নিজের ব্যাকআপগুলো পরীক্ষা করে নিন।
