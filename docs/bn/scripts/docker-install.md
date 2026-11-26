# docker-install

🌐 [English](../../en/scripts/docker-install.md) | **বাংলা**

[← ডকুমেন্টেশনের মূল পাতা](../README.md)

## 1. পরিচিতি

`docker-install` স্ক্রিপ্টটি Ubuntu বা Debian সার্ভারে Docker-এর অফিশিয়াল apt repository থেকে Docker Engine ইনস্টল করে। Docker নিজে যে পদ্ধতিতে ইনস্টল করতে বলে, স্ক্রিপ্টটি সেই পদ্ধতিই অনুসরণ করে; তবে এর সাথে বাড়তি নিরাপত্তা যাচাই, আগে থেকে দেখে নেওয়ার সুবিধা (preview) এবং সহজবোধ্য বার্তা যোগ করা হয়েছে।

নতুন VPS বা Dedicated Server নিয়ে কয়েক মিনিটের মধ্যে Docker ও Docker Compose চালু করতে চাইলে এটি ব্যবহার করুন। আরও বিস্তারিত জানতে [Docker](../docker.md) গাইডটি দেখুন।

## 2. কী কাজ করে

- আপনার অপারেটিং সিস্টেম ও CPU architecture সমর্থিত কি না তা যাচাই করে।
- পুরোনো বা সাংঘর্ষিক কোনো Docker প্যাকেজ (যেমন `docker.io`) ইনস্টল থাকলে কাজ থামিয়ে দেয়।
- সহায়ক প্যাকেজ `ca-certificates` ও `curl` ইনস্টল করে।
- Docker-এর signing key ডাউনলোড করে `/etc/apt/keyrings/docker.asc` ফাইলে রাখে এবং সিস্টেমে `gpg` থাকলে key-টির fingerprint Docker-এর প্রকাশিত fingerprint-এর সাথে মিলিয়ে দেখে।
- `/etc/apt/sources.list.d/docker.list` ফাইলে Docker-এর apt repository যোগ করে।
- `docker-ce`, `docker-ce-cli`, `containerd.io`, `docker-buildx-plugin` ও `docker-compose-plugin` ইনস্টল করে।
- `docker` সার্ভিস চালু করে এবং প্রতিবার বুটের সময় নিজে থেকে চালু হওয়ার ব্যবস্থা করে।
- আপনি চাইলে একজন ব্যবহারকারীকে `docker` গ্রুপে যোগ করে।
- শেষে ইনস্টল হওয়া Docker ও Compose-এর ভার্সন দেখায়।

Docker Engine (`docker-ce`) আগে থেকেই ইনস্টল থাকলে স্ক্রিপ্টটি কিছুই পরিবর্তন করে না, শুধু ইনস্টল থাকা ভার্সনটি জানিয়ে দেয়।

## 3. সমর্থিত অপারেটিং সিস্টেম

| ডিস্ট্রিবিউশন | ভার্সন | Architecture |
| --- | --- | --- |
| Ubuntu | 22.04, 24.04, 26.04 | `amd64`, `arm64` |
| Debian | 12, 13 | `amd64`, `arm64` |

অন্য যেকোনো সিস্টেমে স্ক্রিপ্টটি কোনো পরিবর্তন করার আগেই থেমে যায়। বিস্তারিত: [সমর্থিত অপারেটিং সিস্টেম](../supported-os.md)।

## 4. যা যা প্রয়োজন

- Root permission: **অবশ্যই লাগবে**। কমান্ডটি `sudo` দিয়ে চালান। `--dry-run` ব্যবহার করলেও root permission লাগে।
- সচল ইন্টারনেট সংযোগ, যাতে আপনার apt mirror এবং `download.docker.com`-এ পৌঁছানো যায়।
- ready-fast ইনস্টল করা থাকতে হবে ([ইনস্টলেশন](../installation.md) দেখুন)।
- Docker প্যাকেজগুলোর জন্য ডিস্কে প্রায় 500 MB খালি জায়গা।

## 5. ইনস্টলেশন কমান্ড

প্রথমে preview দেখে নিন। এতে প্রতিটি ধাপ দেখানো হয়, কিন্তু সিস্টেমে কিছুই পরিবর্তন হয় না:

```bash
sudo ready-fast run docker-install --dry-run
```

এরপর ইনস্টল করুন:

```bash
sudo ready-fast run docker-install
```

স্ক্রিপ্টটি কী কী করতে যাচ্ছে তার তালিকা দেখিয়ে জিজ্ঞেস করবে: `Install Docker Engine now? [y/N]:`। এগিয়ে যেতে `y` লিখে Enter চাপুন। অন্য যেকোনো উত্তর দিলে কোনো পরিবর্তন ছাড়াই কাজ বাতিল হয়ে যাবে।

`deploy` নামের ব্যবহারকারী যেন `sudo` ছাড়াই Docker ব্যবহার করতে পারে, সেটাও একসাথে করতে চাইলে:

```bash
sudo ready-fast run docker-install --user deploy
```

## 6. ধাপে ধাপে ব্যাখ্যা

স্ক্রিপ্টটি আপনার হয়ে নিচের কমান্ডগুলো চালায়। এখানে `<ID>` মানে `ubuntu` অথবা `debian`, `<arch>` মানে আপনার CPU architecture এবং `<codename>` মানে আপনার সিস্টেমের রিলিজের সাংকেতিক নাম (যেমন `noble`)।

**ধাপ 1 — প্রয়োজনীয় প্যাকেজ ইনস্টল**

```bash
apt-get update
apt-get install -y ca-certificates curl
```

প্রথম লাইনটি প্যাকেজের তালিকা হালনাগাদ করে। দ্বিতীয় লাইনটি সার্টিফিকেট ও ডাউনলোড করার টুল ইনস্টল করে, যেগুলো HTTPS দিয়ে Docker-এর key নামাতে লাগে। স্ক্রিপ্টটি `apt-get`-কে `DEBIAN_FRONTEND=noninteractive` এবং 120 সেকেন্ডের lock timeout-ও দিয়ে দেয়, যাতে এটি কখনো প্রশ্ন করে থেমে না থাকে এবং প্যাকেজ-সংক্রান্ত অন্য কোনো কাজ চললে অপেক্ষা করে; হুবহু কমান্ডগুলো `--dry-run` দিয়ে দেখে নিতে পারেন।

**ধাপ 2 — Docker-এর signing key ডাউনলোড**

```bash
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/<ID>/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
```

প্রথম লাইনটি key রাখার ডিরেক্টরি তৈরি করে। দ্বিতীয় লাইনটি সেই key ডাউনলোড করে, যা দিয়ে apt যাচাই করে যে প্যাকেজগুলো সত্যিই Docker-এর কাছ থেকে এসেছে। তৃতীয় লাইনটি key ফাইলটিকে apt-এর জন্য পাঠযোগ্য করে। ডাউনলোডের আগে স্ক্রিপ্টটি দেখে নেয় Docker-এর repository-তে আপনার রিলিজের জন্য প্যাকেজ আছে কি না; না থাকলে এটি থেমে যায় এবং apt-এ কিছুই যোগ করে না।

**ধাপ 3 — Docker-এর apt repository যোগ করা**

স্ক্রিপ্টটি `/etc/apt/sources.list.d/docker.list` ফাইলে এই একটি লাইন লেখে:

```text
deb [arch=<arch> signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/<ID> <codename> stable
```

এই লাইনটি apt-কে জানায় Docker-এর প্যাকেজ কোথায় পাওয়া যাবে এবং সেগুলোর জন্য কোন key-কে বিশ্বাস করতে হবে।

**ধাপ 4 — Docker ইনস্টল**

```bash
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

নতুন repository-টি যাতে apt দেখতে পায়, সেজন্য প্যাকেজের তালিকা আবার হালনাগাদ করা হয়। এরপর Docker Engine, এর command-line client, container runtime, Buildx এবং Compose plugin ইনস্টল হয়।

**ধাপ 5 — সার্ভিস চালু করা**

```bash
systemctl enable --now docker
```

এতে Docker এখনই চালু হয় এবং প্রতিবার রিবুটের পর নিজে থেকেই চালু হয়। systemd চালু না থাকলে (যেমন কোনো container-এর ভেতরে) একটি সতর্কবার্তা দেখিয়ে এই ধাপটি বাদ দেওয়া হয়।

**ঐচ্ছিক — ব্যবহারকারীকে docker গ্রুপে যোগ করা** (শুধু `--user` দিলে)

```bash
usermod -aG docker deploy
```

**যাচাই**

```bash
docker --version
docker compose version
```

## 7. কমান্ড অপশন

| অপশন | অর্থ |
| --- | --- |
| `--user <name>` | আগে থেকে থাকা এই ব্যবহারকারীকে `docker` গ্রুপেও যোগ করে, যাতে তিনি `sudo` ছাড়াই `docker` চালাতে পারেন। এরপর ওই ব্যবহারকারীকে একবার লগআউট করে আবার লগইন করতে হবে। |
| `--dry-run` | কী কী করা হবে তা দেখায়, কিন্তু কিছুই পরিবর্তন করে না। |
| `--yes` | নিশ্চিতকরণের প্রশ্ন জিজ্ঞেস করে না। টার্মিনাল ছাড়া (যেমন অন্য কোনো স্ক্রিপ্ট থেকে) কমান্ডটি চালাতে হলে এটি লাগে। |
| `--help` | সাহায্য-বার্তা দেখিয়ে বের হয়ে যায়। |

## 8. প্রত্যাশিত আউটপুট

সফলভাবে ইনস্টল হলে আউটপুট নিচের মতো দেখাবে। `apt-get`-এর লেখা লাইনগুলো ছোট করে `...` দেখানো হয়েছে, আর আপনার ক্ষেত্রে ভার্সন নম্বর ভিন্ন হবে:

```text
[INFO] System: Ubuntu 24.04.5 LTS (amd64)
[INFO] The following will be done:
[INFO]   1. Install the packages ca-certificates and curl
[INFO]   2. Save Docker's signing key to /etc/apt/keyrings/docker.asc
[INFO]   3. Add Docker's apt repository in /etc/apt/sources.list.d/docker.list
[INFO]   4. Install: docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
[INFO]   5. Enable and start the docker service
Install Docker Engine now? [y/N]: y
[INFO] Step 1/5: installing prerequisites
...
[INFO] Step 2/5: downloading Docker's signing key
[OK] Signing key fingerprint verified.
[INFO] Step 3/5: adding Docker's apt repository
[INFO] Step 4/5: installing Docker packages
...
[INFO] Step 5/5: enabling the docker service
[INFO] Verifying the installation
Docker version 29.9.3, build 5457199
Docker Compose version v5.7.1
[OK] The docker service is running.
[OK] Docker Engine is ready. Test it with: sudo docker run --rm hello-world
```

সিস্টেমে `gpg` ইনস্টল না থাকলে `[OK] Signing key fingerprint verified.` লাইনটির বদলে একটি সতর্কবার্তা আসবে যে fingerprint যাচাই করা হয়নি।

Docker আগে থেকেই ইনস্টল থাকলে:

```text
[OK] Docker Engine is already installed: Docker version 29.9.3, build 5457199
[INFO] Skipping installation.
[INFO] Verifying the installation
Docker version 29.9.3, build 5457199
Docker Compose version v5.7.1
[OK] The docker service is running.
[OK] Docker Engine is ready. Test it with: sudo docker run --rm hello-world
```

## 9. নিরাপত্তা বিষয়ক সতর্কতা

- **docker গ্রুপ মানেই root-এর সমান ক্ষমতা।** `docker` গ্রুপের যেকোনো সদস্য এমন container চালাতে পারেন, যা সার্ভারের যেকোনো ফাইল পড়তে বা বদলাতে পারে। তাই যাঁকে `sudo` দিতেও ভরসা করেন, শুধু তাঁর জন্যই `--user` ব্যবহার করুন।
- **Docker UFW-কে পাশ কাটাতে পারে।** `-p` দিয়ে প্রকাশ করা container port (যেমন `-p 8080:80`) UFW-তে অনুমতি না থাকলেও ইন্টারনেট থেকে খোলা থাকে, কারণ Docker নিজের আলাদা firewall rule লেখে। কোনো সার্ভিস গোপন রাখতে চাইলে সেটি শুধু localhost-এ প্রকাশ করুন, যেমন `-p 127.0.0.1:8080:80`। বিস্তারিত: [Firewall](../firewall.md)।
- স্ক্রিপ্টটি একটি third-party apt repository (`download.docker.com`) যোগ করে। এরপর থেকে `apt-get upgrade` চালালে Docker-এর আপডেট সেখান থেকেই ইনস্টল হবে।
- signing key ডাউনলোড হয় HTTPS দিয়ে। এর fingerprint শুধু তখনই যাচাই হয়, যখন `gpg` ইনস্টল থাকে; না থাকলে একটি সতর্কবার্তা দেখানো হয়।
- স্ক্রিপ্টটি Docker daemon-এর কনফিগারেশন বদলায় না এবং firewall-এ কোনো port খোলে না।

## 10. সিস্টেমে যেসব পরিবর্তন হয়

- নতুন প্যাকেজ: `ca-certificates`, `curl`, `docker-ce`, `docker-ce-cli`, `containerd.io`, `docker-buildx-plugin`, `docker-compose-plugin` এবং এগুলোর dependency।
- নতুন ফাইল: `/etc/apt/keyrings/docker.asc` ও `/etc/apt/sources.list.d/docker.list`।
- বুটের সময় চালু হওয়া নতুন সার্ভিস: `docker` ও `containerd`।
- Docker `docker0` নামে একটি network interface এবং নিজের firewall (iptables/nftables) rule তৈরি করে।
- `docker` নামে একটি গ্রুপ তৈরি হয়। `--user` দিলে নির্দিষ্ট ব্যবহারকারী ওই গ্রুপের সদস্য হন।
- পরবর্তীতে image, container ও volume জমা হবে `/var/lib/docker` ডিরেক্টরিতে।

## 11. আগের অবস্থায় ফিরে যাওয়া (Rollback)

**সতর্কতা:** `/var/lib/docker` ও `/var/lib/containerd` মুছে ফেললে সব image, container ও volume চিরতরে মুছে যায়। দরকারি সবকিছুর ব্যাকআপ আগে নিয়ে নিন।

Docker প্যাকেজগুলো সরিয়ে ফেলুন:

```bash
sudo apt-get purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

স্ক্রিপ্টের যোগ করা repository ও key মুছে ফেলুন:

```bash
sudo rm -f /etc/apt/sources.list.d/docker.list /etc/apt/keyrings/docker.asc
sudo apt-get update
```

শুধু যদি Docker-এর সব ডেটাও মুছে ফেলতে চান:

```bash
sudo rm -rf /var/lib/docker /var/lib/containerd
```

`--user` ব্যবহার করে থাকলে ব্যবহারকারীকে গ্রুপ থেকে আবার বাদ দিন:

```bash
sudo gpasswd -d deploy docker
```

`ca-certificates` ও `curl` প্যাকেজ দুটি রেখে দেওয়া হয়, কারণ আরও অনেক প্রোগ্রামের এগুলো দরকার হয়।

## 12. সমস্যা সমাধান

| সমস্যা | কারণ ও সমাধান |
| --- | --- |
| `This script must be run as root.` | কমান্ডটি `sudo` দিয়ে চালান। |
| `Unsupported operating system` | আপনার সিস্টেমটি 3 নম্বর অংশের টেবিলে নেই। সেখানে এই স্ক্রিপ্ট ব্যবহার করা যাবে না। |
| `Conflicting packages are installed` | `docker.io`-এর মতো কোনো পুরোনো Docker প্যাকেজ ইনস্টল আছে। বার্তায় দেখানো `apt-get remove` কমান্ড দিয়ে তালিকার প্যাকেজগুলো সরিয়ে স্ক্রিপ্টটি আবার চালান। |
| `Docker's repository has no packages for '<codename>', or download.docker.com is unreachable.` | `ready-fast run network-info --check` দিয়ে ইন্টারনেট সংযোগ ও DNS পরীক্ষা করুন। নেটওয়ার্ক ঠিক থাকলে বুঝতে হবে Docker এখনো আপনার রিলিজের জন্য প্যাকেজ প্রকাশ করেনি। |
| `The downloaded key has an unexpected fingerprint` | ডাউনলোড হওয়া ফাইলটি Docker-এর key নয়। আপনার সার্ভার ও `download.docker.com`-এর মাঝখানে কিছু একটা (কোনো proxy বা ত্রুটিপূর্ণ mirror) ফাইলটি বদলে দিয়েছে। নেটওয়ার্ক নির্ভরযোগ্য না হওয়া পর্যন্ত এগোবেন না। |
| `apt-get update` চালালে `Conflicting values set for option Signed-By` দেখিয়ে ব্যর্থ হয় | `/etc/apt/sources.list.d/`-এর অন্য কোনো ফাইলে আগে থেকেই ভিন্ন key path দিয়ে Docker repository লেখা আছে। বাড়তি ফাইলটি মুছে স্ক্রিপ্টটি আবার চালান। |
| `Docker is installed but the docker service is not running.` | `journalctl -u docker --no-pager -n 50` দিয়ে সার্ভিসের লগ পড়ে দেখুন। |
| `permission denied while trying to connect to the Docker daemon socket` | আপনার ব্যবহারকারী `docker` গ্রুপে নেই, অথবা গ্রুপে যোগ করার পর লগআউট করে আবার লগইন করা হয়নি। `sudo docker ...` ব্যবহার করুন অথবা নতুন করে লগইন করুন। |

সাধারণ সমস্যাগুলোর সমাধান পাবেন [সমস্যা সমাধান](../troubleshooting.md) পাতায়।

## 13. টেস্টিং স্ট্যাটাস

| কী পরীক্ষা করা হয় | কীভাবে পরীক্ষা করা হয় |
| --- | --- |
| Shell syntax ও প্রচলিত ভুল | প্রতিটি push-এ CI-তে `shellcheck` চালিয়ে |
| অপশন যাচাই, অসমর্থিত OS শনাক্তকরণ, root যাচাই, `--dry-run` | CI-তে `tests/smoke.sh` চালিয়ে |
| সত্যিকারের ইনস্টলেশন, দ্বিতীয়বার চালানো (আগে থেকে ইনস্টল থাকা অবস্থায়), `--user` | CI-তে `tests/system.sh` চালিয়ে; Ubuntu 22.04, 24.04, 26.04 এবং Debian 12, 13-এর `amd64` container-এর ভেতরে |
| systemd দিয়ে `docker` সার্ভিস চালু হওয়া | স্বয়ংক্রিয়ভাবে পরীক্ষা করা হয় না (CI-এর container-গুলোতে systemd নেই) |
| `arm64` | পরীক্ষা করা হয়নি |

এই স্ক্রিপ্টের ওপর নির্ভর করার আগে production নয় এমন একটি সার্ভারে পরীক্ষা করে নিন।
