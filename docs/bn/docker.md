# Docker

🌐 [English](../en/docker.md) | **বাংলা**

[← ডকুমেন্টেশনের মূল পাতা](README.md)

Docker অ্যাপ্লিকেশন চালায় container-এর ভেতরে। Container হলো ছোট, আলাদা করে রাখা একটি প্যাকেজ, যার মধ্যে একটি প্রোগ্রাম এবং সেটি চালাতে যা যা লাগে তার সবই থাকে। ফলে একটি ওয়েবসাইট, একটি database কিংবা পুরো একটি application stack এক কমান্ডেই চালু করা যায়, আবার সার্ভারে কোনো চিহ্ন না রেখেই সরিয়ে ফেলা যায়।

এই গাইডে দেখানো হয়েছে কীভাবে ready-fast দিয়ে Docker ইনস্টল করবেন, প্রথম container-গুলো চালাবেন এবং নতুনদের সবচেয়ে বেশি ভোগায় এমন দুটি ভুল এড়াবেন। ইনস্টলেশন স্ক্রিপ্টটি ঠিক কীভাবে কাজ করে, তা লেখা আছে [docker-install](scripts/docker-install.md) পাতায়।

## Docker ইনস্টল করুন

আগে ইনস্টলেশনের preview দেখুন, তারপর চালান:

```bash
sudo ready-fast run docker-install --dry-run
sudo ready-fast run docker-install
```

- Root permission: লাগবে।
- যা ইনস্টল হয়: Docker-এর অফিশিয়াল apt repository থেকে Docker Engine, `docker` কমান্ড, containerd, Buildx ও Compose plugin।
- ঝুঁকি: নতুন একটি system service ও নতুন একটি software source যোগ হয়। আগে থেকে থাকা কিছুই সরানো হয় না। `docker.io`-এর মতো পুরোনো Docker প্যাকেজ থাকলে স্ক্রিপ্টটি থেমে গিয়ে আপনাকে জানিয়ে দেয়।

## প্রথম container চালান

```bash
sudo docker run --rm hello-world
```

- `docker run` একটি image থেকে container চালু করে। `hello-world` image-টি প্রথমবার নিজে থেকেই ডাউনলোড হয়ে যায়।
- `--rm` দিলে কাজ শেষ হওয়ার পর container-টি আবার মুছে যায়।

প্রত্যাশিত আউটপুট (সংক্ষেপিত):

```text
Hello from Docker!
This message shows that your installation appears to be working correctly.
...
```

## বাস্তব উদাহরণ: একটি web server

nginx web server-টি background-এ চালু করুন, যাতে শুধু সার্ভারের ভেতর থেকেই সেটিতে পৌঁছানো যায়:

```bash
sudo docker run -d --name web -p 127.0.0.1:8080:80 nginx
```

- `-d` container-টিকে background-এ চালায়।
- `--name web` container-টির একটি নাম দেয়, যাতে পরে সেই নাম ধরে কাজ করা যায়।
- `-p 127.0.0.1:8080:80` সার্ভারের port 8080-কে (শুধু local address-এ) container-এর ভেতরের port 80-এর সাথে যুক্ত করে।

সেটি সাড়া দিচ্ছে কি না দেখুন:

```bash
curl -I http://127.0.0.1:8080
```

উত্তরের প্রথম লাইনটি `HTTP/1.1 200 OK` হওয়ার কথা।

কী কী চলছে দেখুন, তারপর container-টি থামিয়ে মুছে ফেলুন:

```bash
sudo docker ps
sudo docker stop web
sudo docker rm web
```

## sudo ছাড়া Docker ব্যবহার

ডিফল্টভাবে শুধু root-ই Docker-এর সাথে যোগাযোগ করতে পারে। `deploy` ব্যবহারকারী যেন সরাসরি `docker` চালাতে পারেন, সেজন্য:

```bash
sudo ready-fast run docker-install --user deploy
```

এরপর ওই ব্যবহারকারীকে লগআউট করে আবার লগইন করতে হবে। Docker আগে থেকে ইনস্টল থাকলেও এটি কাজ করে; সে ক্ষেত্রে স্ক্রিপ্টটি শুধু ব্যবহারকারীকে গ্রুপে যোগ করে।

**সতর্কতা:** `docker` গ্রুপের সদস্যরা সার্ভারে root হয়ে যেতে পারেন, কারণ একটি container host-এর যেকোনো ফাইল mount করে বদলে ফেলতে পারে। যাঁরা `sudo`-ও ব্যবহার করতে পারেন, শুধু তাঁদেরই এই অধিকার দিন।

## Docker Compose

একসাথে কাজ করে এমন কয়েকটি container-কে Compose একটিমাত্র ফাইল থেকে চালু করে। এটি plugin হিসেবে ইনস্টল হয়, তাই কমান্ডটি হলো মাঝখানে space দিয়ে `docker compose`; পুরোনো `docker-compose` নয়:

```bash
docker compose version
```

## Docker ও firewall

সার্ভারে Docker ব্যবহারের ক্ষেত্রে এই বিষয়টি বোঝা সবচেয়ে জরুরি।

Docker নিজের firewall rule নিজেই পরিচালনা করে। `-p 8080:80` দিয়ে আপনি যে port প্রকাশ করেন, সেটিতে পুরো ইন্টারনেট থেকে পৌঁছানো যায়; **UFW চালু থাকলেও এবং তাতে port 8080-এর কোনো rule না থাকলেও**। অনেকেই ধরে নেন UFW তাঁদের সুরক্ষা দিচ্ছে, আর না জেনেই database উন্মুক্ত করে ফেলেন।

- যেসব সার্ভিসে শুধু সার্ভার নিজে অথবা একই সার্ভারের কোনো reverse proxy পৌঁছাবে, সেগুলো local address-এ প্রকাশ করুন: `-p 127.0.0.1:8080:80`।
- যেসব সার্ভিস সত্যিই সবার জন্য উন্মুক্ত থাকা দরকার, শুধু সেগুলোই সব address-এ প্রকাশ করুন (`-p 80:80`)।
- Container চালু করার পর `sudo ready-fast run network-info` চালিয়ে "Listening ports" অংশে দেখে নিন কী কী খোলা আছে।

UFW সম্পর্কে আরও জানতে [Firewall](firewall.md) গাইডটি দেখুন।

## Docker আপডেট করা

অন্য সব প্যাকেজের মতো Docker-ও apt দিয়ে আপডেট হয়:

```bash
sudo apt-get update
sudo apt-get install --only-upgrade docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

আপডেটের সময় Docker সার্ভিস restart হয়, তখন চলমান container-গুলো থেমে যায়। তাই আপডেটের জন্য এমন সময় বেছে নিন, যখন কাজের চাপ কম থাকে।

## ডিস্কের জায়গার দিকে নজর রাখুন

Image, থেমে থাকা container ও build cache `/var/lib/docker`-এ ডিস্কের জায়গা দখল করে।

```bash
sudo docker system df
```

এই কমান্ডটি দেখায় Docker কতটুকু জায়গা ব্যবহার করছে। জায়গা খালি করতে:

```bash
sudo docker system prune
```

**সতর্কতা:** এই কমান্ডটি থেমে থাকা সব container, অব্যবহৃত network, dangling image ও build cache মুছে ফেলে। মোছার আগে এটি নিশ্চিতকরণ চায়। Volume মোছা হয় না।

## Docker সরিয়ে ফেলা

[docker-install](scripts/docker-install.md) পাতার "আগের অবস্থায় ফিরে যাওয়া (Rollback)" অংশটি অনুসরণ করুন। মনে রাখবেন, `/var/lib/docker` মুছে ফেললে সব image, container ও volume নষ্ট হয়ে যায়।

## প্রচলিত সমস্যা

| সমস্যা | সমাধান |
| --- | --- |
| `permission denied while trying to connect to the Docker daemon socket` | `sudo` ব্যবহার করুন, অথবা ওপরে দেখানো নিয়মে আপনার ব্যবহারকারীকে `docker` গ্রুপে যোগ করে আবার লগইন করুন। |
| `Cannot connect to the Docker daemon` | সার্ভিসটি চালু নেই। `sudo systemctl status docker` দিয়ে অবস্থা দেখুন এবং `sudo systemctl start docker` দিয়ে চালু করুন। |
| `port is already allocated` | অন্য কোনো প্রোগ্রাম বা container আগে থেকেই এই port ব্যবহার করছে। `-p`-এর বাঁ পাশে অন্য একটি port নম্বর দিন। |
| Image ডাউনলোড খুব ধীর অথবা ব্যর্থ হচ্ছে | `ready-fast run network-info --check` দিয়ে সংযোগ পরীক্ষা করুন। |

আরও সমাধান পাবেন [docker-install](scripts/docker-install.md) পাতার সমস্যা সমাধান অংশে এবং [সমস্যা সমাধান](troubleshooting.md) পাতায়।
