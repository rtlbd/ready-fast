# সমর্থিত অপারেটিং সিস্টেম

🌐 [English](../en/supported-os.md) | **বাংলা**

[← ডকুমেন্টেশনের মূল পাতা](README.md)

ready-fast লেখা হয়েছে Ubuntu ও Debian সার্ভারের জন্য। এই পাতায় নির্দিষ্ট ভার্সনগুলোর তালিকা আছে, প্রতিটি স্ক্রিপ্টের ক্ষেত্রে "সমর্থিত" বলতে কী বোঝায় তার ব্যাখ্যা আছে এবং নিজের সিস্টেম কীভাবে পরীক্ষা করবেন তা দেখানো হয়েছে।

## সমর্থিত সিস্টেম

| ডিস্ট্রিবিউশন | ভার্সন | Codename | Architecture |
| --- | --- | --- | --- |
| Ubuntu | 22.04 LTS | `jammy` | `amd64`, `arm64` |
| Ubuntu | 24.04 LTS | `noble` | `amd64`, `arm64` |
| Ubuntu | 26.04 LTS | `resolute` | `amd64`, `arm64` |
| Debian | 12 | `bookworm` | `amd64`, `arm64` |
| Debian | 13 | `trixie` | `amd64`, `arm64` |

`amd64` হলো প্রচলিত 64-bit Intel বা AMD প্রসেসর, যা বেশির ভাগ VPS ও Dedicated Server-এ ব্যবহার হয়। `arm64` হলো 64-bit ARM প্রসেসর, যা কিছু cloud server-এ পাওয়া যায়।

## নিজের সিস্টেম কীভাবে পরীক্ষা করবেন

আপনার অপারেটিং সিস্টেমের নাম ও ভার্সন দেখুন:

```bash
cat /etc/os-release
```

`ID`, `VERSION_ID` ও `VERSION_CODENAME` লাইনগুলো লক্ষ করুন। ready-fast ঠিক এই তিনটি মানই পড়ে।

আপনার প্রসেসরের architecture দেখুন:

```bash
dpkg --print-architecture
```

অথবা ready-fast দিয়েই সবকিছু একবারে পরীক্ষা করিয়ে নিন:

```bash
ready-fast doctor
```

`OS:` ও `Architecture:` লাইন দুটির শেষে `(supported)` অথবা `(NOT supported)` লেখা থাকে।

## প্রতিটি স্ক্রিপ্টের ক্ষেত্রে "সমর্থিত" বলতে কী বোঝায়

যেসব স্ক্রিপ্ট সফটওয়্যার ইনস্টল করে বা সিস্টেমের সেটিং বদলায়, সেগুলো ওপরের টেবিলে নেই এমন সিস্টেমে চলতে রাজি হয় না। কোনো কিছু বদলানোর আগেই সেগুলো `Unsupported operating system` বার্তা দেখিয়ে থেমে যায়। আর যেসব স্ক্রিপ্ট শুধু তথ্য পড়ে অথবা শুধু আপনার বলে দেওয়া ফাইল নিয়ে কাজ করে, সেগুলো অপারেটিং সিস্টেম যাচাই করে না।

| স্ক্রিপ্ট | OS যাচাই করে | Architecture যাচাই করে | systemd লাগে |
| --- | --- | --- | --- |
| [docker-install](scripts/docker-install.md) | হ্যাঁ | হ্যাঁ | সার্ভিস চালু করার জন্য |
| [firewall-setup](scripts/firewall-setup.md) | হ্যাঁ | না | না |
| [ssh-hardening](scripts/ssh-hardening.md) | হ্যাঁ | না | সার্ভিস reload করার জন্য |
| [network-info](scripts/network-info.md) | না | না | না |
| [system-monitor](scripts/system-monitor.md) | না | না | শুধু ব্যর্থ সার্ভিসের তালিকার জন্য |
| [backup-create](scripts/backup-create.md) | না | না | না |
| [backup-restore](scripts/backup-restore.md) | না | না | না |

যেসব স্ক্রিপ্ট অপারেটিং সিস্টেম যাচাই করে না, সেগুলো সাধারণত অন্য Linux ডিস্ট্রিবিউশনেও কাজ করবে; তবে পরীক্ষা করা হয়েছে শুধু টেবিলের সিস্টেমগুলোতে।

## যেসব পরিবেশে সীমাবদ্ধতা আছে

- **systemd ছাড়া container** (যেমন কোনো Docker container): স্ক্রিপ্ট চলে, কিন্তু সার্ভিস নিজে থেকে চালু বা reload করা যায় না। স্ক্রিপ্টগুলো একটি সতর্কবার্তা দেখিয়ে এগিয়ে যায়।
- **Container-ভিত্তিক VPS (OpenVZ, LXC):** এখানে kernel-টি host-এর সাথে ভাগাভাগি করে ব্যবহার হয়। এ ধরনের VPS-এ প্রায়ই UFW চালু করা যায় না, Docker-ও না চলতে পারে। আপনার provider-কে জিজ্ঞেস করুন।
- **Desktop সংস্করণ:** Ubuntu Desktop এবং desktop-সহ Debian সার্ভার সংস্করণের মতো একই ভার্সনের মান দেখায়, তাই স্ক্রিপ্টগুলো চলে। তবে এগুলো আলাদা করে পরীক্ষা করা হয়নি।
- **WSL (Windows Subsystem for Linux):** পরীক্ষা করা হয়নি।

## যা সমর্থিত নয়

- **পুরোনো রিলিজ**, যেমন Ubuntu 20.04 ও Debian 11। এগুলোর নিয়মিত সাপোর্টের মেয়াদ শেষ হয়ে গেছে; নতুন সার্ভার এগুলোর ওপর তৈরি করা উচিত নয়।
- **Ubuntu বা Debian-ভিত্তিক, কিন্তু নিজস্ব পরিচয় ব্যবহার করে এমন ডিস্ট্রিবিউশন**, যেমন Linux Mint বা Kali Linux। এগুলোর `ID` মান আলাদা, তাই যাচাইয়ে এগুলো বাদ পড়ে যায়।
- **Red Hat পরিবার** (RHEL, Rocky Linux, AlmaLinux, CentOS, Fedora)। এগুলো `apt-get`-এর বদলে `dnf` package manager ব্যবহার করে।
- **অন্যান্য ডিস্ট্রিবিউশন**, যেমন Arch Linux, Alpine Linux ও openSUSE।

এই যাচাইটি বন্ধ করা যায় না। এটি ইচ্ছাকৃত: যে স্ক্রিপ্ট সিস্টেমের কনফিগারেশন সম্পাদনা করে, সেটি অচেনা সিস্টেমে চললে সত্যিকারের ক্ষতি করে ফেলতে পারে।

## সাপোর্ট কীভাবে পরীক্ষা করা হয়

Repository-তে প্রতিটি push-এ GitHub Actions-এ এই স্বয়ংক্রিয় টেস্টগুলো চলে:

| টেস্ট | কোথায় চলে | কী কী পরীক্ষা করে |
| --- | --- | --- |
| `shellcheck` | GitHub-এর Ubuntu virtual machine | প্রতিটি shell ফাইলের static analysis। |
| `tests/smoke.sh` | একই virtual machine-এ এবং প্রতিটি সমর্থিত সিস্টেমের container-এর ভেতরে | কমান্ড, অপশন, root ও অপারেটিং সিস্টেমের যাচাই, শুধু তথ্য পড়ে এমন স্ক্রিপ্ট এবং একটি পূর্ণাঙ্গ ব্যাকআপ ও restore। |
| container-এ `tests/system.sh` | Ubuntu 22.04, 24.04, 26.04 এবং Debian 12, 13-এর `amd64` container | ready-fast ইনস্টল করা, সত্যিকারের Docker ইনস্টলেশন এবং SSH সেটিং প্রয়োগ করা ও আগের অবস্থায় ফেরানো। |
| virtual machine-এ `tests/system.sh` | systemd-সহ GitHub-এর Ubuntu 22.04 ও 24.04 virtual machine | SSH সার্ভিস reload করা এবং firewall সত্যি সত্যি চালু করা। |

জানা সীমাবদ্ধতা: `arm64` স্বয়ংক্রিয়ভাবে পরীক্ষা করা হয় না, এবং firewall সত্যি সত্যি চালু করে দেখা হয় শুধু Ubuntu 22.04 ও 24.04-এ। বিস্তারিত তথ্য প্রতিটি স্ক্রিপ্টের পাতার "টেস্টিং স্ট্যাটাস" অংশে আছে।

## অন্য কোনো সিস্টেমের জন্য অনুরোধ করা

তালিকায় নেই এমন কোনো সিস্টেম আপনার দরকার হলে `https://github.com/rtlbd/ready-fast/issues`-এ একটি issue খুলুন এবং সাথে `cat /etc/os-release`-এর আউটপুট দিন।
