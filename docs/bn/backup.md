# ব্যাকআপ

🌐 [English](../en/backup.md) | **বাংলা**

[← ডকুমেন্টেশনের মূল পাতা](README.md)

আজ হোক বা কাল, প্রতিটি সার্ভারই কোনো না কোনো সময় ডেটা হারায়: একটি ভুল কমান্ড, নষ্ট হয়ে যাওয়া ডিস্ক, hack হওয়া ওয়েবসাইট কিংবা বিল পরিশোধ না হওয়া। ব্যাকআপ থাকলে এমন দিনটি বিপর্যয়ের বদলে সামান্য ঝামেলায় পরিণত হয়। এই গাইডে ready-fast দিয়ে ব্যাকআপ নেওয়ার একটি সহজ নিয়ম দেখানো হয়েছে।

এই গাইডের পেছনের দুটি স্ক্রিপ্টের বিবরণ আছে [backup-create](scripts/backup-create.md) ও [backup-restore](scripts/backup-restore.md) পাতায়।

## কার্যকর ব্যাকআপের তিনটি নিয়ম

1. **যা নতুন করে তৈরি করা সম্ভব নয়, তার ব্যাকআপ নিন।** কনফিগারেশন, ওয়েবসাইটের ফাইল, upload করা বিষয়বস্তু এবং database dump।
2. **একটি কপি অন্য কোথাও রাখুন।** যে ব্যাকআপ শুধু একই সার্ভারে থাকে, সেটি সার্ভারের সাথেই হারিয়ে যায়।
3. **Restore পরীক্ষা করুন।** যে ব্যাকআপ কখনো restore করে দেখা হয়নি, সেটি কেবলই একটি আশা।

## কীসের ব্যাকআপ নেবেন

| Path | সাধারণত যা থাকে | ব্যাকআপ নেবেন? |
| --- | --- | --- |
| `/etc` | সিস্টেম ও সার্ভিসের কনফিগারেশন | হ্যাঁ |
| `/var/www` | ওয়েবসাইটের ফাইল | হ্যাঁ, যদি ওয়েবসাইট host করেন |
| `/home` | ব্যবহারকারীদের ফাইল | হ্যাঁ, যদি সেগুলো গুরুত্বপূর্ণ হয় |
| আপনার application-এর ডিরেক্টরি | Code, upload, কনফিগারেশন | হ্যাঁ |
| Database dump রাখার ডিরেক্টরি | Export করা database (নিচে দেখুন) | হ্যাঁ |
| `/proc`, `/sys`, `/dev`, `/run`, `/tmp` | Virtual ও সাময়িক ফাইল | না |
| `/var/lib/docker` | Docker-এর কাঁচা ডেটা | না। এর বদলে আপনার Compose ফাইল ও volume-এর ডেটার ব্যাকআপ নিন। |

পুরো সিস্টেমের (`/`) ব্যাকআপ নেওয়ার সুবিধা ready-fast-এ নেই। সার্ভারের পূর্ণাঙ্গ image-এর জন্য এই ফাইল-ব্যাকআপের পাশাপাশি আপনার hosting provider-এর snapshot সুবিধা ব্যবহার করুন।

## ব্যাকআপ তৈরি করুন

আগে preview দেখুন, তারপর চালান:

```bash
sudo ready-fast run backup-create --source /etc --source /var/www --name web --dry-run
sudo ready-fast run backup-create --source /etc --source /var/www --name web
```

- Root permission: এখানে লাগবে, কারণ `/etc`-এ এমন ফাইল আছে যা শুধু root পড়তে পারে, আর ডিফল্ট destination-এর মালিকও root।
- ঝুঁকি: আপনার ডেটার জন্য কোনো ঝুঁকি নেই; source শুধু পড়া হয়। Archive-টি `/var/backups/ready-fast`-এ ডিস্কের জায়গা নেয়।

ফলাফল হিসেবে `web-20261126-023000.tar.gz`-এর মতো একটি archive এবং একই নামের শেষে `.sha256` যোগ করা একটি checksum ফাইল তৈরি হয়।

## Database-এর ক্ষেত্রে আগে dump লাগে

চালু থাকা database-এর data directory-র (যেমন `/var/lib/mysql`) ব্যাকআপ নেবেন না। কপি হওয়ার সময়ই ফাইলগুলো বদলাতে থাকে, ফলে কপিটি অকেজো হয়ে যেতে পারে। আগে database-টি একটি ফাইলে export করুন, তারপর সেই ফাইলের ব্যাকআপ নিন।

MySQL বা MariaDB-র উদাহরণ; এমন সার্ভারের জন্য, যেখানে `root` পাসওয়ার্ড ছাড়াই database-এ সংযোগ করতে পারে (Ubuntu ও Debian-এ এটিই ডিফল্ট):

```bash
sudo mkdir -p /var/backups/db
sudo sh -c 'mysqldump --all-databases > /var/backups/db/mysql-all.sql'
sudo ready-fast run backup-create --source /var/backups/db --name db --keep 7
```

- প্রথম লাইনটি dump রাখার জন্য একটি ডিরেক্টরি তৈরি করে।
- দ্বিতীয় লাইনটি সব database একটি ফাইলে export করে।
- তৃতীয় লাইনটি ওই ডিরেক্টরির ব্যাকআপ নেয় এবং সবচেয়ে নতুন 7টি archive রেখে দেয়।

একই কাজের জন্য PostgreSQL-এ আছে `pg_dumpall` টুল। আপনার database-এর ডকুমেন্টেশন অনুসরণ করুন।

## ডিস্ক যেন ভরে না যায়

প্রতিবার চালালে একটি নতুন archive তৈরি হয়। `--keep` দিলে ব্যাকআপ সফল হওয়ার পর একই নামের পুরোনো archive-গুলো মুছে ফেলা হয়:

```bash
sudo ready-fast run backup-create --source /etc --source /var/www --name web --keep 14
```

**সতর্কতা:** মুছে ফেলা archive আর ফিরিয়ে আনা যায় না, এবং মোছার আগে স্ক্রিপ্টটি জিজ্ঞেসও করে না। ভিন্ন `--name`-এর archive-এ কখনো হাত দেওয়া হয় না; তাই যে ব্যাকআপ স্থায়ীভাবে রাখতে চান, তার জন্য আলাদা নাম ব্যবহার করুন।

## প্রতি রাতে নিজে থেকে ব্যাকআপ নিন

root ব্যবহারকারীর সময়সূচিটি খুলুন:

```bash
sudo crontab -e
```

একদম শেষে এই লাইনটি যোগ করুন, তারপর save করে editor বন্ধ করুন:

```cron
30 2 * * * /usr/local/bin/ready-fast run backup-create --source /etc --source /var/www --name web --keep 14 >> /var/log/ready-fast-backup.log 2>&1
```

- `30 2 * * *` মানে "প্রতিদিন 02:30-এ"; সার্ভারের time zone অনুযায়ী।
- পুরো path `/usr/local/bin/ready-fast` ব্যবহার করা হয়েছে, কারণ cron অল্প কয়েকটি ডিরেক্টরিই চেনে।
- লাইনের শেষ অংশটি আউটপুটকে `/var/log/ready-fast-backup.log` নামের log ফাইলে লিখে রাখে।

পরের দিন দেখে নিন নতুন একটি archive তৈরি হয়েছে কি না:

```bash
sudo ls -lh /var/backups/ready-fast
```

স্বয়ংক্রিয় ব্যাকআপ বন্ধ করতে আবার `sudo crontab -e` চালিয়ে লাইনটি মুছে দিন।

## সার্ভারের বাইরে একটি কপি রাখুন

নিচের অন্তত একটি উপায় বেছে নিন:

- **অন্য একটি মেশিন।** `rsync` দিয়ে ব্যাকআপের ডিরেক্টরিটি দ্বিতীয় কোনো সার্ভারে অথবা আপনার অফিসের কোনো কম্পিউটারে পাঠিয়ে দিন। এই উদাহরণে `backup@203.0.113.20` হলো অন্য মেশিনটির এমন একজন ব্যবহারকারী, যাঁর কাছে আপনার সার্ভার SSH key দিয়ে পৌঁছাতে পারে:

```bash
sudo rsync -a /var/backups/ready-fast/ backup@203.0.113.20:backups/web-01/
```

  `-a` দিলে permission ও সময় ঠিক থাকে। Source path-এর শেষের `/` চিহ্নটির অর্থ "এই ডিরেক্টরির ভেতরের সবকিছু"। দুটি মেশিনেই `rsync` ইনস্টল থাকতে হবে।

- **অন্য একটি ডিস্ক।** সার্ভারে দ্বিতীয় কোনো ডিস্ক বা network storage mount করা থাকলে `--dest` দিয়ে ব্যাকআপ সরাসরি সেখানেই লিখুন; নিয়মটি [backup-create](scripts/backup-create.md) পাতায় দেখানো আছে।
- **Provider-এর snapshot।** বাড়তি হিসেবে কাজের, তবে এগুলো সাধারণত সার্ভারের সাথে একই account ও একই data centre-এ থাকে।

Archive **এনক্রিপ্ট করা থাকে না**। সার্ভারের বাইরে যা কিছু যাবে, তা আগে এনক্রিপ্ট করে নেওয়া উচিত, যেমন `gpg --symmetric` দিয়ে; আর passphrase-টি অবশ্যই সার্ভারের বাইরে কোনো নিরাপদ জায়গায় রাখতে হবে।

## Restore পরীক্ষা করুন

ব্যাকআপের ব্যবস্থা করার পরপরই এটি করুন, এরপর কয়েক মাস পরপর।

**1. Archive যাচাই করে ভেতরটা দেখুন:**

```bash
sudo ready-fast run backup-restore --file /var/backups/ready-fast/web-20261126-023000.tar.gz --list
```

আউটপুটের প্রথম লাইনটি অবশ্যই `[OK] Checksum verified` হতে হবে।

**2. একটি পরীক্ষামূলক ডিরেক্টরিতে extract করুন:**

```bash
sudo ready-fast run backup-restore --file /var/backups/ready-fast/web-20261126-023000.tar.gz --target /tmp/restore-test
```

**3. একটি ফাইল মূল ফাইলের সাথে মিলিয়ে দেখুন, তারপর পরিষ্কার করে ফেলুন:**

```bash
sudo diff /etc/hostname /tmp/restore-test/etc/hostname
sudo rm -rf /tmp/restore-test
```

ফাইল দুটি হুবহু এক হলে `diff` কিছুই দেখায় না।

## ভুল হয়ে যাওয়ার পর restore করা

কোনো ফাইল নষ্ট হলে বা মুছে গেলে পুরো archive সিস্টেমের ওপর restore করবেন না। ওপরে দেখানো নিয়মে একটি পরীক্ষামূলক ডিরেক্টরিতে extract করুন এবং শুধু দরকারি ফাইলটি কপি করে ফিরিয়ে নিন:

```bash
sudo cp -a /tmp/restore-test/etc/hostname /etc/hostname
```

`cp -a` ফাইলের মালিকানা ও permission ঠিক রাখে। `--target /` দিয়ে সবকিছু মূল জায়গায় restore করলে বর্তমান ফাইলগুলো overwrite হয়ে যায় এবং তা আর ফেরানো যায় না; এমনটি করার আগে [backup-restore](scripts/backup-restore.md) পাতার নিরাপত্তা-সংক্রান্ত অংশটি পড়ে নিন।

## এই ব্যাকআপের সীমাবদ্ধতা

- কোনো এনক্রিপশন নেই। Archive-গুলো আপনাকেই সুরক্ষিত রাখতে হবে।
- Incremental ব্যাকআপ নেই। প্রতিটি archive একটি পূর্ণাঙ্গ কপি, তাই বড় ডিরেক্টরির জন্য অনেক জায়গা লাগে।
- চালু থাকা database-এর নির্ভরযোগ্য কপি হয় না। Dump ব্যবহার করুন।
- পুরো সিস্টেম বা bare-metal recovery-র সুবিধা নেই।
- অন্য মেশিনে নিজে থেকে কপি যায় না। সে ব্যবস্থা আপনাকেই করতে হবে।

## আরও সাহায্য

Error বার্তাগুলোর ব্যাখ্যা আছে [backup-create](scripts/backup-create.md) ও [backup-restore](scripts/backup-restore.md) পাতায়। সাধারণ সাহায্য পাবেন [সমস্যা সমাধান](troubleshooting.md) পাতায়।
