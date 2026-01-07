# 00_snapshot.ps1
# Lightweight forensic snapshot for WRCCDC

$ts = Get-Date -Format "yyyyMMdd_HHmmss"
$base = "C:\CCDC\Backups\$ts"
New-Item -ItemType Directory -Path $base -Force | Out-Null

Write-Host "Creating snapshot at $base"

# Firewall
netsh advfirewall export "$base\firewall.wfw" | Out-Null

# Users & admins
net user > "$base\local_users.txt"
net localgroup administrators > "$base\local_admins.txt"

# Services
Get-Service | Sort-Object Status,Name | Out-File "$base\services.txt"

# Network
netstat -ano > "$base\netstat.txt"

# Scheduled tasks
schtasks /query /fo LIST /v > "$base\schtasks.txt"

Write-Host "Snapshot complete."
