# ইনস্টলেশন

🌐 [English](../en/installation.md) | **বাংলা**

[← ডকুমেন্টেশনের মূল পাতা](README.md)

এই পাতায় দেখানো হয়েছে কীভাবে ready-fast ডাউনলোড ও ইনস্টল করবেন, এটি ঠিকমতো কাজ করছে কি না যাচাই করবেন, আপডেট করবেন এবং প্রয়োজনে আবার সরিয়ে ফেলবেন। পুরো কাজটিতে মিনিট দুয়েক সময় লাগে।

## যা যা প্রয়োজন

- সমর্থিত সিস্টেমের একটি সার্ভার বা কম্পিউটার: Ubuntu 22.04, 24.04, 26.04 অথবা Debian 12, 13। বিস্তারিত: [সমর্থিত অপারেটিং সিস্টেম](supported-os.md)।
- `sudo` ব্যবহার করতে পারেন এমন একজন ব্যবহারকারী, অথবা সরাসরি `root` ব্যবহারকারী। আপনি `root` হিসেবে লগইন করে থাকলে সব কমান্ড থেকে `sudo` শব্দটি বাদ দিন।
- ইন্টারনেট সংযোগ।
- `git` প্রোগ্রাম; এটি ধাপ 1-এ ইনস্টল করা হবে।

## ধাপ 1 — git ইনস্টল করুন

```bash
sudo apt-get update
sudo apt-get install -y git
```

- প্রথম লাইনটি পাওয়া যায় এমন প্যাকেজের তালিকা হালনাগাদ করে।
- দ্বিতীয় লাইনটি `git` ইনস্টল করে; এই টুল দিয়েই ready-fast-এর ফাইলগুলো ডাউনলোড করা হয়। `-y` দিলে ইনস্টলের প্রশ্নের উত্তরে নিজে থেকেই "yes" ধরে নেওয়া হয়।
- Root permission: লাগবে (`sudo`)।
- ঝুঁকি: একটি প্রচলিত প্যাকেজ ইনস্টল হওয়া ছাড়া আর কিছু নয়।

## ধাপ 2 — ready-fast ডাউনলোড করুন

```bash
git clone https://github.com/rtlbd/ready-fast.git
cd ready-fast
```

- প্রথম লাইনটি আপনি এখন যে ডিরেক্টরিতে আছেন তার ভেতরে `ready-fast` নামে একটি নতুন ডিরেক্টরি তৈরি করে প্রজেক্টটি সেখানে ডাউনলোড করে।
- দ্বিতীয় লাইনটি দিয়ে ওই ডিরেক্টরিতে প্রবেশ করা হয়।
- Root permission: লাগবে না।
- ঝুঁকি: নেই। নতুন ডিরেক্টরিটির বাইরে কিছুই স্পর্শ করা হয় না।

## ধাপ 3 — ইনস্টলের আগে দেখে নিন

এই ধাপটি ঐচ্ছিক, তবে করে নেওয়াই ভালো। ready-fast ডাউনলোড করা ডিরেক্টরি থেকেই সরাসরি চলতে পারে, তাই কিছু ইনস্টল হওয়ার আগেই আপনি এটি দেখে নিতে পারেন:

```bash
./ready-fast list
./ready-fast doctor
```

- প্রথম লাইনটি সব স্ক্রিপ্টের তালিকা দেখায়।
- দ্বিতীয় লাইনটি আপনার সিস্টেম সমর্থিত কি না তা পরীক্ষা করে।
- Root permission: লাগবে না। দুটি কমান্ডই শুধু তথ্য পড়ে।

স্ক্রিপ্টগুলো `scripts` ডিরেক্টরিতে থাকা সাধারণ text ফাইল। চালানোর আগে সেগুলো পড়ে দেখতে আপনাকে উৎসাহিত করা হচ্ছে।

## ধাপ 4 — ইনস্টল করুন

```bash
sudo ./install.sh
```

এই কমান্ডটি যা করে:

- Toolkit-টি `/opt/ready-fast`-এ কপি করে। সেখানে পুরোনো কোনো কপি থাকলে তার জায়গায় নতুনটি বসে।
- `/usr/local/bin/ready-fast` নামে একটি link তৈরি করে, যাতে যেকোনো ডিরেক্টরি থেকে `ready-fast` কমান্ডটি কাজ করে।
- Root permission: লাগবে, কারণ দুটি জায়গাই সিস্টেমের অংশ।
- ঝুঁকি: `/opt/ready-fast`-এর ভেতরে আপনি নিজে হাতে কিছু বদলে থাকলে তা হারিয়ে যাবে। সিস্টেমের আর কিছুই বদলায় না। `/usr/local/bin/ready-fast` আগে থেকেই থাকলে এবং সেটি অন্য কোনো প্রোগ্রামের সাধারণ ফাইল হলে installer থেমে যায় এবং কিছুই বদলায় না।

প্রত্যাশিত আউটপুট:

```text
[OK] Installed ready-fast 0.1.0 to /opt/ready-fast
[OK] Command available: /usr/local/bin/ready-fast
[INFO] Next step: ready-fast doctor
```

## ধাপ 5 — যাচাই করুন

```bash
ready-fast version
ready-fast doctor
```

প্রথম কমান্ডের প্রত্যাশিত আউটপুট:

```text
ready-fast 0.1.0
```

নতুন একটি সার্ভারে দ্বিতীয় কমান্ডের প্রত্যাশিত আউটপুট। "Optional tools"-এর লাইনগুলো নির্ভর করে সিস্টেমে কী কী ইনস্টল আছে তার ওপর:

```text
ready-fast doctor

  OS:            Ubuntu 24.04.5 LTS (supported)
  Architecture:  amd64 (supported)
  Privileges:    normal user (use sudo for scripts that change the system)
  systemd:       running

  Required tools:
    apt-get      found
    dpkg         found
    tar          found
    sha256sum    found
    awk          found
    grep         found
    sed          found

  Optional tools:
    curl         found
    ip           found
    ss           found
    systemctl    found
    sshd         found
    ufw          not installed
    docker       not installed

[OK] This system is ready for ready-fast.
```

শেষ লাইনটি `[ERROR]` দিয়ে শুরু হলে `NOT supported` বা `MISSING` লেখা লাইনগুলো থেকেই বুঝতে পারবেন সমস্যাটি কোথায়।

ব্যস, আপনি প্রস্তুত। এবার [দ্রুত শুরু](quick-start.md) পাতায় যান।

## আপডেট করা

ডাউনলোড করা ডিরেক্টরিতে ফিরে গিয়ে সবচেয়ে নতুন ভার্সনটি নামিয়ে আবার ইনস্টল করুন:

```bash
cd ready-fast
git pull
sudo ./install.sh
```

ready-fast আপডেট করলে কোনো স্ক্রিপ্ট নতুন করে চলে না, এবং আগে কোনো স্ক্রিপ্ট যে সফটওয়্যার ইনস্টল করেছে তাতেও কোনো পরিবর্তন হয় না।

## সরিয়ে ফেলা (Uninstall)

```bash
sudo ./install.sh --uninstall
```

প্রত্যাশিত আউটপুট:

```text
[OK] Removed /opt/ready-fast and /usr/local/bin/ready-fast
```

এতে শুধু ready-fast নিজেই সরে যায়। স্ক্রিপ্টগুলো যা যা করেছে, তা এতে আগের অবস্থায় ফেরে **না**:

- স্ক্রিপ্টের তৈরি করা সফটওয়্যার ও সেটিং (Docker, firewall rule, SSH সেটিং) যেমন আছে তেমনই থাকে। সেগুলো সরাতে চাইলে uninstall করার **আগে** প্রতিটি স্ক্রিপ্টের ডকুমেন্টের "আগের অবস্থায় ফিরে যাওয়া (Rollback)" অংশ অনুসরণ করুন।
- `/var/backups/ready-fast`-এর ব্যাকআপগুলো রেখে দেওয়া হয়।
- ডাউনলোড করা `ready-fast` ডিরেক্টরিটি রেখে দেওয়া হয়। আর দরকার না হলে সেটি নিজেই মুছে ফেলুন।

## ইন্টারনেট থেকে এক লাইনে ইনস্টল করার ব্যবস্থা কেন নেই

অনেক প্রজেক্ট এমন একটি কমান্ড দেয়, যা একটি স্ক্রিপ্ট ডাউনলোড করে সঙ্গে সঙ্গে root হিসেবে চালিয়ে দেয়। ready-fast ইচ্ছা করেই তা করে না। `git clone` করলে আপনি এমন একটি কপি পান, যা আগে পড়ে দেখা যায়; আর ঠিক কোন ভার্সনটি ইনস্টল করেছেন, তা-ও আপনার সবসময় জানা থাকে।

## সমস্যা সমাধান

| সমস্যা | কারণ ও সমাধান |
| --- | --- |
| `git: command not found` | আগে ধাপ 1 সম্পন্ন করুন। |
| `install.sh must be run as root.` | কমান্ডটি `sudo` দিয়ে চালান। |
| ইনস্টলের পর `ready-fast: command not found` | `/usr/local/bin` আপনার `PATH`-এ নেই। পুরো path `/usr/local/bin/ready-fast` ব্যবহার করুন, অথবা লগআউট করে আবার লগইন করুন। |
| `exists and is not a symlink` | একই নামের অন্য একটি ফাইল পথ আটকে আছে। সেটি অন্য কোথাও সরিয়ে installer আবার চালান। |
| `is missing. Run install.sh from a complete copy of the repository.` | ডাউনলোড অসম্পূর্ণ। ডিরেক্টরিটি মুছে ধাপ 2 আবার করুন। |

আরও সাহায্য পাবেন [সমস্যা সমাধান](troubleshooting.md) পাতায়।
