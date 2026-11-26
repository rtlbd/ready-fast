# ssh-hardening

🌐 [English](../../en/scripts/ssh-hardening.md) | **বাংলা**

[← ডকুমেন্টেশনের মূল পাতা](../README.md)

## 1. পরিচিতি

`ssh-hardening` স্ক্রিপ্টটি OpenSSH সার্ভারকে (যে প্রোগ্রামটি আপনার SSH লগইন গ্রহণ করে) আরও নিরাপদ করে। ইন্টারনেটে থাকা প্রতিটি সার্ভারে বিভিন্ন bot সারাক্ষণ পাসওয়ার্ড অনুমান করে ঢোকার চেষ্টা করে। তাই নতুন সার্ভারে প্রথম দিকের কাজগুলোর একটি হলো SSH-কে শক্ত করা।

স্ক্রিপ্টটি মূল কনফিগারেশন ফাইল `/etc/ssh/sshd_config` কখনো সম্পাদনা করে না এবং SSH port কখনো বদলায় না। এটি নিজের সেটিংগুলো আলাদা একটি ফাইলে লেখে, ফলে একটি মাত্র কমান্ড দিয়েই সবকিছু আগের অবস্থায় ফিরিয়ে নেওয়া যায়। সামগ্রিক ধারণার জন্য [নিরাপত্তা](../security.md) গাইডটি দেখুন।

## 2. কী কাজ করে

- OpenSSH সার্ভার ইনস্টল আছে কি না এবং `/etc/ssh/sshd_config` ফাইলটি `/etc/ssh/sshd_config.d/` থেকে ফাইল লোড করে কি না তা যাচাই করে।
- নিচে উল্লেখ করা সেটিংগুলো দিয়ে `/etc/ssh/sshd_config.d/00-ready-fast.conf` ফাইলটি লেখে।
- যেসব অপশন দিলে আর কেউই লগইন করতে পারবে না, সেগুলো প্রত্যাখ্যান করে।
- `sshd -t` দিয়ে নতুন কনফিগারেশন পরীক্ষা করে। পরীক্ষা ব্যর্থ হলে পরিবর্তনটি নিজে থেকেই বাতিল হয়ে যায়।
- SSH সার্ভিস reload করে, যাতে নতুন সংযোগগুলোতে সেটিংগুলো কার্যকর হয়।
- এখন কোন কোন সেটিং কার্যকর আছে তা দেখায়।

যে সেটিংগুলো সবসময় প্রয়োগ হয়:

| সেটিং | ফলাফল |
| --- | --- |
| `PermitEmptyPasswords no` | যেসব অ্যাকাউন্টের পাসওয়ার্ড ফাঁকা, সেগুলো দিয়ে লগইন করা যায় না। |
| `MaxAuthTries 4` | লগইনের চেষ্টা 4 বার ব্যর্থ হলে সংযোগ বন্ধ করে দেওয়া হয়। |
| `LoginGraceTime 30` | 30 সেকেন্ডের মধ্যে লগইন সম্পন্ন না হলে সংযোগ বন্ধ করে দেওয়া হয়। |
| `X11Forwarding no` | Graphical forwarding বন্ধ থাকে; সার্ভারে এটি সাধারণত দরকার হয় না। |
| `ClientAliveInterval 300` ও `ClientAliveCountMax 2` | কোনো client সাড়া দেওয়া বন্ধ করলে প্রায় 10 মিনিট পর তার সংযোগ বিচ্ছিন্ন করা হয়। |

যে সেটিংগুলো শুধু আপনি চাইলে প্রয়োগ হয়:

| অপশন | যে সেটিং লেখা হয় | ফলাফল |
| --- | --- | --- |
| `--root-login <mode>` | `PermitRootLogin <mode>` | `root` SSH দিয়ে লগইন করতে পারবে কি না তা নিয়ন্ত্রণ করে। |
| `--disable-password-auth` | `PasswordAuthentication no` ও `KbdInteractiveAuthentication no` | শুধু SSH key গ্রহণ করা হয়; পাসওয়ার্ড প্রত্যাখ্যান করা হয়। |

## 3. সমর্থিত অপারেটিং সিস্টেম

| ডিস্ট্রিবিউশন | ভার্সন |
| --- | --- |
| Ubuntu | 22.04, 24.04, 26.04 |
| Debian | 12, 13 |

অন্য যেকোনো সিস্টেমে স্ক্রিপ্টটি কোনো পরিবর্তন করার আগেই থেমে যায়। বিস্তারিত: [সমর্থিত অপারেটিং সিস্টেম](../supported-os.md)।

## 4. যা যা প্রয়োজন

- Root permission: **অবশ্যই লাগবে**। কমান্ডটি `sudo` দিয়ে চালান। `--dry-run` ব্যবহার করলেও root permission লাগে।
- OpenSSH সার্ভার (`openssh-server` প্যাকেজ) ইনস্টল থাকতে হবে।
- ready-fast ইনস্টল করা থাকতে হবে ([ইনস্টলেশন](../installation.md) দেখুন)।
- `--disable-password-auth`-এর জন্য: আপনার SSH public key আগে থেকেই সার্ভারের `~/.ssh/authorized_keys` ফাইলে থাকতে হবে।
- জোরালো পরামর্শ: পরীক্ষা করার সময় চলমান SSH সেশনটি খোলা রাখুন এবং hosting provider-এর web console হাতের কাছে রাখুন।

## 5. ইনস্টলেশন কমান্ড

প্রথমে preview দেখে নিন। এতে কোন ফাইল লেখা হবে তা দেখানো হয়, কিন্তু কিছুই পরিবর্তন হয় না:

```bash
sudo ready-fast run ssh-hardening --dry-run
```

প্রাথমিক সেটিংগুলো প্রয়োগ করুন। এগুলো কে লগইন করতে পারবে তা বদলায় না:

```bash
sudo ready-fast run ssh-hardening
```

`root` যেন শুধু SSH key দিয়ে লগইন করতে পারে, পাসওয়ার্ড দিয়ে কখনো নয়:

```bash
sudo ready-fast run ssh-hardening --root-login prohibit-password
```

সবচেয়ে কঠোর ব্যবস্থা: root লগইন পুরোপুরি বন্ধ এবং পাসওয়ার্ড দিয়ে লগইনও বন্ধ। একজন সাধারণ ব্যবহারকারী SSH key দিয়ে লগইন করতে পারছেন এবং `sudo` ব্যবহার করতে পারছেন, এটা নিশ্চিত হওয়ার পরেই কেবল এটি করুন:

```bash
sudo ready-fast run ssh-hardening --root-login no --disable-password-auth
```

প্রতিবার চালানোর সময় ফাইলটি পুরোপুরি নতুন করে লেখা হয়। যে অপশন আপনি বাদ দেবেন, সেটি ফাইল থেকেও বাদ পড়ে যাবে; তাই যে অপশনগুলো রাখতে চান, প্রতিবার সবগুলোই দিন।

## 6. ধাপে ধাপে ব্যাখ্যা

**ধাপ 1 — যাচাই।** স্ক্রিপ্টটি root permission ও অপারেটিং সিস্টেম যাচাই করে, `sshd` আছে কি না দেখে এবং `/etc/ssh/sshd_config` ফাইলে `Include /etc/ssh/sshd_config.d/*.conf` লাইনটি আছে কি না পরীক্ষা করে। এই লাইনটি না থাকলে আলাদা ফাইলের কোনো প্রভাব পড়ে না, তাই স্ক্রিপ্টটি থেমে যায়।

**ধাপ 2 — আটকে পড়া থেকে সুরক্ষা।** স্ক্রিপ্টটি সার্ভারের অ্যাকাউন্টগুলো দেখে (`root` এবং UID 1000 বা তার বেশি এমন সাধারণ ব্যবহারকারী, যাঁদের login shell আছে):

- বিকল্প হিসেবে লগইন করতে পারেন এমন কোনো সাধারণ ব্যবহারকারী না থাকলে `--root-login no` প্রত্যাখ্যান করা হয়।
- `root`-এর কোনো SSH key না থাকলে এবং কোনো সাধারণ ব্যবহারকারীও না থাকলে `--root-login prohibit-password` প্রত্যাখ্যান করা হয়।
- লগইনের অনুমতি আছে এমন কোনো অ্যাকাউন্টের `~/.ssh/authorized_keys` ফাইলে SSH key না থাকলে `--disable-password-auth` প্রত্যাখ্যান করা হয়।

**ধাপ 3 — নিশ্চিতকরণ।** নতুন ফাইলে হুবহু কী লেখা হবে তা দেখিয়ে আপনাকে জিজ্ঞেস করা হয়: `Apply these SSH settings? [y/N]:`।

**ধাপ 4 — ফাইল লেখা।** `/etc/ssh/sshd_config.d/00-ready-fast.conf` আগে থেকে থাকলে তার একটি কপি `/var/backups/ready-fast/ssh-hardening/` ডিরেক্টরিতে রাখা হয়। এরপর নতুন ফাইলটি `0600` permission দিয়ে লেখা হয়। ফাইলের নাম `00-` দিয়ে শুরু, কারণ OpenSSH প্রতিটি সেটিংয়ের জন্য প্রথমে যে মানটি পড়ে সেটিই ব্যবহার করে; ফলে ডিরেক্টরির অন্য ফাইলের (যেমন `50-cloud-init.conf`) চেয়ে ready-fast-এর ফাইলটি অগ্রাধিকার পায়।

**ধাপ 5 — কনফিগারেশন পরীক্ষা।**

```bash
sshd -t
```

এই কমান্ডটি OpenSSH-কে পুরো কনফিগারেশন প্রয়োগ না করে শুধু পরীক্ষা করতে বলে। কোনো ত্রুটি পাওয়া গেলে স্ক্রিপ্টটি আগের অবস্থা ফিরিয়ে এনে থেমে যায়; চলমান SSH সার্ভিসে হাত দেওয়া হয় না।

**ধাপ 6 — সার্ভিস reload করা।**

```bash
systemctl reload ssh
```

Reload করলে SSH সার্ভিস নতুন কনফিগারেশন পড়ে নেয়। আপনার সেশনসহ চলমান সব সেশন সংযুক্তই থাকে।

**ধাপ 7 — ফলাফল দেখানো।**

```bash
sshd -T
```

স্ক্রিপ্টটি এই আউটপুট ছেঁকে শুধু সেই সেটিংগুলো দেখায়, যেগুলো এটি নিজে নিয়ন্ত্রণ করে।

## 7. কমান্ড অপশন

| অপশন | অর্থ |
| --- | --- |
| `--root-login <mode>` | `PermitRootLogin` ঠিক করে। `<mode>` হতে পারে `yes` (root পাসওয়ার্ড বা key দিয়ে লগইন করতে পারবে), `prohibit-password` (root শুধু SSH key দিয়ে লগইন করতে পারবে) অথবা `no` (root SSH দিয়ে লগইন করতে পারবে না)। এই অপশন না দিলে বর্তমান সেটিং অপরিবর্তিত থাকে। |
| `--disable-password-auth` | সবার জন্য পাসওয়ার্ড দিয়ে লগইন বন্ধ করে। এরপর শুধু SSH key কাজ করে। |
| `--rollback` | এই স্ক্রিপ্টের লেখা ফাইলটি মুছে SSH সার্ভিস reload করে। ওপরের দুটি অপশনের সাথে একসাথে ব্যবহার করা যায় না। |
| `--dry-run` | কী কী করা হবে তা দেখায়, কিন্তু কিছুই পরিবর্তন করে না। |
| `--yes` | নিশ্চিতকরণের প্রশ্ন জিজ্ঞেস করে না। |
| `--help` | সাহায্য-বার্তা দেখিয়ে বের হয়ে যায়। |

## 8. প্রত্যাশিত আউটপুট

`sudo ready-fast run ssh-hardening` চালালে এই আউটপুট আসে:

```text
[INFO] System: Ubuntu 24.04.5 LTS
[INFO] This file will be written: /etc/ssh/sshd_config.d/00-ready-fast.conf
    # Managed by ready-fast (ssh-hardening). Do not edit by hand.
    # Remove with: ready-fast run ssh-hardening --rollback
    PermitEmptyPasswords no
    MaxAuthTries 4
    LoginGraceTime 30
    X11Forwarding no
    ClientAliveInterval 300
    ClientAliveCountMax 2
Apply these SSH settings? [y/N]: y
[OK] sshd accepted the new configuration.
[OK] The SSH service was reloaded.
[INFO] Settings now in effect:
    logingracetime 30
    maxauthtries 4
    clientaliveinterval 300
    clientalivecountmax 2
    permitrootlogin without-password
    passwordauthentication yes
    kbdinteractiveauthentication no
    x11forwarding no
    permitemptypasswords no
[OK] Done. Keep this session open and test a new SSH login from another terminal.
```

`permitrootlogin` ও `passwordauthentication`-এর মান আপনার সার্ভার এবং আপনার দেওয়া অপশনের ওপর নির্ভর করে। OpenSSH `prohibit-password` মোডটিকে `without-password` নামে দেখায়; দুটি নামের অর্থ একই।

বিপজ্জনক কোনো অপশন প্রত্যাখ্যান করা হলে:

```text
[ERROR] Refusing --disable-password-auth: no account that is allowed to log in has an SSH key in ~/.ssh/authorized_keys. Add your public key first. Nothing was changed.
```

## 9. নিরাপত্তা বিষয়ক সতর্কতা

- **নিজেকে সার্ভারের বাইরে আটকে ফেলার ঝুঁকি।** `--disable-password-auth` ও `--root-login` ঠিক করে দেয় কে লগইন করতে পারবে। চলমান সেশনটি খোলা রাখুন, দ্বিতীয় একটি টার্মিনাল খুলুন এবং নতুন লগইন কাজ করছে নিশ্চিত হওয়ার আগে কিছুই বন্ধ করবেন না।
- আটকে পড়া থেকে সুরক্ষার ব্যবস্থাটি একটি বাড়তি নিরাপত্তা-জাল মাত্র, নিশ্চয়তা নয়। এটি শুধু দেখে key ফাইল আছে কি না; এর সাথে মেলে এমন private key এখনো আপনার কাছে আছে কি না, কিংবা আপনার সাধারণ ব্যবহারকারীর `sudo` ব্যবহারের অনুমতি আছে কি না, তা এটি জানতে পারে না।
- `authorized_keys` ফাইলের শুধু সাধারণ key লাইনগুলোই গণনায় ধরা হয়। `command="..."`-এর মতো অপশন দিয়ে শুরু হওয়া লাইন বাদ দেওয়া হয়, কারণ এ ধরনের key প্রায়ই সীমিত ক্ষমতার হয় এবং স্বাভাবিক shell খুলতে পারে না।
- শুধু প্রাথমিক সেটিংগুলো দিয়ে পাসওয়ার্ড অনুমানের চেষ্টা ঠেকানো যায় না। প্রকৃত সুরক্ষার জন্য SSH key-এর সাথে `--disable-password-auth` ব্যবহার করুন এবং [firewall-setup](firewall-setup.md) দিয়ে প্রবেশাধিকার সীমিত করুন।
- স্ক্রিপ্টটি SSH port, host key, অনুমোদিত cipher কিংবা কোন ব্যবহারকারী ও গ্রুপ লগইন করতে পারবে, এসবের কিছুই বদলায় না।

## 10. সিস্টেমে যেসব পরিবর্তন হয়

- নতুন ফাইল: `/etc/ssh/sshd_config.d/00-ready-fast.conf`।
- ফাইলটি বদলানো বা মুছে ফেলার সময় পুরোনো সংস্করণটি `/var/backups/ready-fast/ssh-hardening/` ডিরেক্টরিতে কপি করে রাখা হয়।
- SSH সার্ভিস reload হয়। চালু থাকা সেশনগুলো বিচ্ছিন্ন হয় না।
- `/etc/ssh/sshd_config.d/`-এর অন্য ফাইলে বা `/etc/ssh/sshd_config`-এ একই নামের সেটিং থাকলে সেগুলো আর কার্যকর থাকে না, কারণ ready-fast-এর ফাইলটি সবার আগে পড়া হয়।
- সাড়া না দেওয়া SSH client-এর সংযোগ প্রায় 10 মিনিট পর বিচ্ছিন্ন হয়; লগইন 30 সেকেন্ডের মধ্যে সম্পন্ন করতে হয়।

## 11. আগের অবস্থায় ফিরে যাওয়া (Rollback)

ready-fast-এর সেটিংগুলো সরিয়ে SSH reload করুন:

```bash
sudo ready-fast run ssh-hardening --rollback
```

স্ক্রিপ্টটি ফাইলটির একটি কপি `/var/backups/ready-fast/ssh-hardening/` ডিরেক্টরিতে রেখে ফাইলটি মুছে ফেলে, `sshd -t` দিয়ে কনফিগারেশন পরীক্ষা করে এবং SSH সার্ভিস reload করে। এরপর আপনার সার্ভার ঠিক সেই সেটিংগুলোই ব্যবহার করে, যেগুলো ready-fast চালানোর আগে ছিল।

`ready-fast` কমান্ডটি পাওয়া না গেলে একই কাজ হাতে করুন:

```bash
sudo rm -f /etc/ssh/sshd_config.d/00-ready-fast.conf
sudo sshd -t
sudo systemctl reload ssh
```

SSH দিয়ে আর লগইন করতে না পারলে আপনার hosting provider-এর web console দিয়ে লগইন করে ওপরের কমান্ডগুলো সেখানে চালান।

## 12. সমস্যা সমাধান

| সমস্যা | কারণ ও সমাধান |
| --- | --- |
| `This script must be run as root.` | কমান্ডটি `sudo` দিয়ে চালান। |
| `The OpenSSH server (sshd) is not installed.` | `sudo apt-get install -y openssh-server` দিয়ে ইনস্টল করুন; আর মেশিনটিতে SSH দিয়ে ঢোকার দরকার না থাকলে এই স্ক্রিপ্টটি বাদ দিন। |
| `/etc/ssh/sshd_config does not include /etc/ssh/sshd_config.d/*.conf` | মূল কনফিগারেশন ফাইলটি বদলানো হয়েছে এবং সেটি আর আলাদা ফাইল লোড করে না। `/etc/ssh/sshd_config` ফাইলের একদম ওপরে `Include /etc/ssh/sshd_config.d/*.conf` লাইনটি যোগ করে স্ক্রিপ্টটি আবার চালান। |
| `Refusing --disable-password-auth` | ব্যবহারযোগ্য কোনো SSH key পাওয়া যায়নি। আপনার নিজের কম্পিউটার থেকে `ssh-copy-id deploy@203.0.113.10` চালান (নিজের user name ও সার্ভারের ঠিকানা বসিয়ে), key দিয়ে লগইন হচ্ছে নিশ্চিত করুন, তারপর স্ক্রিপ্টটি আবার চালান। |
| `Refusing --root-login no` | কোনো সাধারণ ব্যবহারকারী নেই। `sudo adduser deploy` দিয়ে একজন তৈরি করুন, `sudo usermod -aG sudo deploy` দিয়ে তাঁকে administrator-এর ক্ষমতা দিন, লগইন পরীক্ষা করুন, তারপর স্ক্রিপ্টটি আবার চালান। |
| `sshd rejected the new configuration, so the change was undone.` | এই বার্তার ওপরে যে error দেখানো হয়, তাতে লেখা থাকে OpenSSH কোন ফাইলের কোন লাইন মেনে নিচ্ছে না। সাধারণত এটি `/etc/ssh/sshd_config`-এর কোনো পুরোনো ভুল। সেটি ঠিক করে স্ক্রিপ্টটি আবার চালান। |
| লগইনের সময় `Too many authentication failures` | আপনার SSH client 4টির বেশি key পাঠানোর চেষ্টা করছে। কোন key ব্যবহার করতে হবে তা বলে দিন: `ssh -o IdentitiesOnly=yes -i ~/.ssh/id_ed25519 deploy@203.0.113.10`। |
| `The ssh service is not running under systemd, so it was not reloaded.` | ফাইলটি লেখা হয়েছে, কিন্তু সার্ভিস reload করা যায়নি (যেমন কোনো container-এর ভেতরে)। SSH সার্ভার পরেরবার চালু হওয়ার সময় সেটিংগুলো কার্যকর হবে। |

সাধারণ সমস্যাগুলোর সমাধান পাবেন [সমস্যা সমাধান](../troubleshooting.md) পাতায়।

## 13. টেস্টিং স্ট্যাটাস

| কী পরীক্ষা করা হয় | কীভাবে পরীক্ষা করা হয় |
| --- | --- |
| Shell syntax ও প্রচলিত ভুল | প্রতিটি push-এ CI-তে `shellcheck` চালিয়ে |
| অপশন যাচাই, অসমর্থিত OS শনাক্তকরণ | CI-তে `tests/smoke.sh` চালিয়ে |
| প্রয়োগ করা, সেটিং কার্যকর হওয়া, অনিরাপদ অপশন প্রত্যাখ্যান, `--root-login no`-এর সাথে `--disable-password-auth`, আগের ফাইলের ব্যাকআপ, `--rollback` | CI-তে `tests/system.sh` চালিয়ে; Ubuntu 22.04, 24.04, 26.04 এবং Debian 12, 13-এর `amd64` container-এর ভেতরে |
| systemd দিয়ে চালু SSH সার্ভিস reload হওয়া | CI-তে `tests/system.sh` চালিয়ে; GitHub-এর Ubuntu 22.04 ও 24.04 virtual machine-এ |
| Hardening-এর পর সত্যিকারের SSH লগইন | স্বয়ংক্রিয়ভাবে পরীক্ষা করা হয় না |
| `arm64` | পরীক্ষা করা হয়নি |

এই স্ক্রিপ্টের ওপর নির্ভর করার আগে production নয় এমন একটি সার্ভারে পরীক্ষা করে নিন।
