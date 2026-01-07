# CCDC-Script
_____________
**Install Git package:**

winget install --id Git.Git -e --source winget
VERIFY
git --version
_____________
Wifi is down, Git is not accessible, try SSH through PuTTy.

Putty needs Ip/Host name.
Run: ipconfig 

Proceed with Git Clone.
______________
**Git Clone:**

(place yourself in base directory)
**cd ~
or
cd C:/**

git clone <repository_url>
ex. **git clone https://github.com/ParkerRubin/CCDC-Script.git** 

THEN cd <repo name>
ex. **cd CCDC-Script**

AFTER cd <sub folder>
ex. **cd scripts**
run ls for script names
______________
**RUN Git Script Files:**

First: **Set-ExecutionPolicy -Scope Process Bypass**

Next,

./(filename).ps1
ex. ./tools.ps1

Order: Snapshots → Triage → Tools → Firewall → Watch
___________________________
**Snapshots**   ./snapshots.ps1     

**netsh advfirewall import "C:\CCDC\Backups\YYYYMMDD_HHMMSS\firewall.wfw"**
Time stamps are provided in file directory

Roll back firewall rules thats it.
_________
**Users/Accounts:**

**get-localuser**

Guest Accounts:

Disable-LocalUser -Name "Guest"
   To Verify:
Get-LocalUser Guest

Admin Accounts:

Disable-LocalUser -Name "Administrator"
   Verify:
Get-LocalUser Administrator
_________

Password Change:
Set-LocalUser -Name "username" -Password (Read-Host -AsSecureString)
(invisible box to type password into)
_________
**Ports:**

Common:
80   → HTTP (web)
443  → HTTPS (secure web)
3389 → RDP (Windows remote desktop)
22   → SSH (Linux / networking)
53   → DNS
25   → SMTP (mail)
445  → SMB (Windows file sharing)
135  → RPC (Windows core service)

Uncommon:
4444  → common backdoor / reverse shell
1337  → meme port, often malicious
6666/6667 → botnets / IRC C2
8080 → web proxy / alt HTTP (can be legit OR bad)
9001–9005 → malware sometimes
5000–6000 → suspicious if public-facing
__________
**Choco Install**

Set-ExecutionPolicy Bypass -Scope Process -Force;
[System.Net.ServicePointManager]::SecurityProtocol = `
[System.Net.ServicePointManager]::SecurityProtocol -bor 3072;
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

choco --version

choco install git -y



