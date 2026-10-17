# 🐴 Horse Plinko (HPCC4) — Blue Team Scripts README

Quick guide to the hardening/recon scripts in this repo, built for the Horse Plinko Cyber Challenge. Pair this with the **Blue Team Guide**. These automate the boring first-15-minutes work so you can spend time hunting Red Team instead of typing the same commands on five boxes.

> **Read before you run anything:**
> - Run everything as **root** (`sudo`), on **your own competition boxes only**.
> - **Test each script on a practice box first.** A typo in a hardening script that breaks SSH or a scored service costs you points.
> - **Save every script's output** (pipe to a file) and copy it to **blackbox (`172.16.t.5`)**, which is out of scope for Red Team.
> - These are Linux scripts for **guidance (Ubuntu 22.04)** and **ignition (Fedora Server 38)**. The Windows boxes (assembly, manifest) are hardened by hand (see the guide).
> - Keep this repo **private** (team scripts are allowed to be private). Red Team should not see your password pattern.

---

## ⏱️ Recommended run order (first 15 minutes)

1. **`inventory.sh`** and **`bad.sh`** — read-only. Snapshot the box and find gaps before you change anything. Save the output to blackbox.
2. **`firstrun.sh`** — baseline hardening, backups, tool install, netcat removal. (Set a safe backup path, see below.)
3. **`passwd.sh`** — rotate every password. **Immediately update `jmoney`'s new password in NEIGH** or you fail scoring. Save the printed CSV to paper.
4. **`iptables.sh`** *or* **`ufw.sh`** (pick one) — firewall. Make sure SSH (22) and every scored port stay open.

Then back up again to blackbox, watch logs / OpenObserve, and start hunting.

---

## 📜 The scripts

### `inventory.sh` — know your box (read-only, safe)
Prints a full snapshot: hostname, IP, OS, **open ports + the process on each**, Docker containers, human users, **admin users (sudo/wheel)**, domain join, mounts, service-tied processes, Kubernetes, and installed services.
- **When:** minute zero, before you change anything. Run it again later and diff to spot what changed.
- **Run:** `sudo ./inventory.sh | tee ~/inventory_$(hostname).txt`
- **Boxes:** guidance, ignition (any Linux).
- **Why it matters:** you can't defend what you haven't mapped. The open-ports and admin-users sections tell you immediately if something is off.

### `bad.sh` — privesc & persistence audit (read-only, safe)
Hunts the ways Red Team escalates or hides: **SUID binaries** that match the GTFOBins list, **file capabilities**, **world-writable files**, full **sudoers** + `NOPASSWD` / `!authenticate` lines, a **sudo version** vuln check, and **LD_PRELOAD / `/etc/ld.so.preload` / `ld.so.conf.d`** (library-hijack rootkit spots).
- **When:** right after inventory, minute zero.
- **Run:** `sudo ./bad.sh | tee ~/bad_$(hostname).txt`
- **Act on it:** strip unexpected SUID with `chmod -s <path>`, remove `NOPASSWD` sudo lines you didn't add, investigate any non-empty `ld.so.preload` (classic rootkit), and fix world-writable config files.

### `firstrun.sh` — the baseline hardener (MAKES CHANGES)
The workhorse. It:
- Detects the distro and **installs defensive tooling** (auditd, rsyslog, rkhunter, tcpdump, nmap, tmux, htop, whowatch, etc.).
- **Removes netcat.**
- **Backs up** `/etc`, `/bin`, `/var/www`, `/root`, plus `/etc/passwd`, `/etc/group`, PAM config, and listening/established ports to a backup folder.
- **Hardens SSH** (`PermitRootLogin no`, `PermitEmptyPasswords no`, disables X11/TCP forwarding) and restarts it.
- **Hardens every `php.ini`** (disables dangerous functions, `expose_php off`, `allow_url_include off`, etc.).
- Locks down perms (`/etc/shadow` 600, `/etc/passwd` 644, `/root` 640), **downloads pspy64 + linpeas**, restarts web servers, and dumps SUID/processes/cron for review.
- **Run:** `sudo BCK=/root ./firstrun.sh` (see the backup note below).
- **Boxes:** guidance, ignition (handles apt and dnf).

> ⚠️ **Three things to know before running `firstrun.sh`:**
> 1. **It disables SELinux.** On **ignition (Fedora)** SELinux is *enforcing* and the guide says don't blindly kill it. Disabling it lowers security and can change service behavior. Decide on purpose, or comment out the `SELINUX=disabled` / `setenforce 0` lines if you want to keep it.
> 2. **Default backup path is `/tmp/initial`.** `/tmp` is world-writable and wiped on reboot, so Red could read or nuke it. Run it with `BCK=/root` (backups go to `/root/initial`), then **scp that folder to blackbox**.
> 3. **It `wget`s pspy64 and linpeas from GitHub**, so it needs internet. The boxes may not have any, so **pre-download both and stage them on blackbox** before comp day.

### `passwd.sh` — rotate every password (MAKES CHANGES)
Generates a unique random **4-word + `123!`** passphrase for **every user with a login shell** (e.g. `HotelCyberWolfMoon123!`), applies it, and prints a `USER,PASSWORD` CSV.
- **When:** right after `firstrun.sh`, still in the first 15 minutes.
- **Run:** `sudo ./passwd.sh | tee ~/passwords_$(hostname).csv`
- **Boxes:** guidance, ignition.

> ⚠️ **Critical follow-ups:**
> - This changes **`jmoney`** (the scoring user) too. The moment it finishes, go to **NEIGH → Users / Modify Scoring User** and set `jmoney`'s new password there, or your own scorechecks fail. **Never disable `jmoney`.**
> - **Write the CSV down on paper** for your team and don't lose it.
> - It does **not** touch app logins (Jenkins admin, MariaDB, OpenWebUI). Change those by hand.

### `iptables.sh` — interactive firewall allowlist (MAKES CHANGES)
The flexible firewall. Flushes existing rules (wiping anything Red planted), sets **default-deny inbound**, keeps loopback + established, then **prompts you for the exact ports to open** and persists the rules. Validates ports and warns if you forget SSH.
- **Run:** `sudo ./iptables.sh` (then type e.g. `22 80` for guidance), or `sudo ./iptables.sh 22 80`.
- **Boxes:** any Linux. On **ignition (Fedora)**, stop firewalld first (`sudo systemctl stop firewalld`) or use firewalld's own rules.
- **Use this** when you want to open only what each box needs. Only the ports you type are allowed.

### `ufw.sh` — quick UFW baseline (MAKES CHANGES)
Resets UFW, sets default **deny in / allow out**, allows a **hardcoded** set (22, 80, 8080, 3306, 445), denies 4444, and enables it.
- **Run:** `sudo ./ufw.sh`
- **Boxes:** **Ubuntu/Mint only** (guidance, blackbox). Fedora/ignition doesn't use UFW by default, use `iptables.sh` or firewalld there.

> ⚠️ **Edit the ports before you run it.** The allowed list is hardcoded. For **guidance** you likely only need **22 and 80**, so 8080/3306/445 are extra attack surface, close what the box doesn't actually serve. Run **either** `ufw.sh` **or** `iptables.sh`, not both.

---

## 🔑 Don't forget (HPCC specifics)

- After **any** password or firewall change, verify **`jmoney` can still log in** and your scored services are still green in NEIGH.
- **Scored ports stay open to any source** (scoring comes from many IPs). Don't lock them to one subnet.
- **Egress still matters.** These firewall scripts lock down inbound; a reverse shell calls *outbound*. Add outbound deny rules too (see the guide's "Deny Red Team Their Tools" section).
- **Copy all outputs and backups to blackbox** (`172.16.t.5`). It's the one box Red can't touch.
- These scripts do the easy wins. Keep **hunting** (cron, systemd timers, authorized_keys, web shells) by hand, no script catches everything.
