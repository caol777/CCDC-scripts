# 01_triage.ps1
# WRCCDC-style triage: READ-ONLY collection (safe baseline)
# Writes artifacts to C:\IR\TRIAGE\<HOST>_<timestamp>\

$ErrorActionPreference = "SilentlyContinue"

$stamp = Get-Date -Format "yyyy-MM-dd_HHmm"
$hostn = $env:COMPUTERNAME
$outDir = "C:\IR\TRIAGE\{0}_{1}" -f $hostn, $stamp

New-Item -ItemType Directory -Path $outDir -Force | Out-Null

function Out-Text($name, $content) {
  $path = Join-Path $outDir $name
  $content | Out-File -FilePath $path -Encoding UTF8 -Force
}

function Try-Run($name, $scriptBlock) {
  try {
    $result = & $scriptBlock
    if ($null -eq $result) { $result = "[no output]" }
    Out-Text $name $result
  } catch {
    Out-Text $name ("[error] " + $_.Exception.Message)
  }
}

# --- System / Network ---
Try-Run "system.txt" {
  $os = Get-CimInstance Win32_OperatingSystem
  $cs = Get-CimInstance Win32_ComputerSystem
  $bios = Get-CimInstance Win32_BIOS

  $ips = Get-NetIPAddress -AddressFamily IPv4 |
    Where-Object { $_.IPAddress -notlike "169.254*" -and $_.IPAddress -ne "127.0.0.1" } |
    Select-Object -ExpandProperty IPAddress

@"
=== SYSTEM ===
Host: $env:COMPUTERNAME
User: $env:USERDOMAIN\$env:USERNAME
Time: $(Get-Date)
OS: $($os.Caption) $($os.Version) (Build $($os.BuildNumber))
Manufacturer/Model: $($cs.Manufacturer) / $($cs.Model)
BIOS: $($bios.SMBIOSBIOSVersion)
Domain/Workgroup: $($cs.Domain)
IPs: $($ips -join ", ")
"@
}

Try-Run "firewall.txt" {
  Get-NetFirewallProfile | Select-Object Name, Enabled, DefaultInboundAction, DefaultOutboundAction, NotifyOnListen, LogAllowed, LogBlocked |
    Format-Table -AutoSize | Out-String
}

Try-Run "netstat.txt" {
  (netstat -ano) | Out-String
}

Try-Run "shares.txt" {
  (net share) | Out-String
}

# --- Users / Admins ---
Try-Run "users_admins.txt" {
  $localUsers = (Get-LocalUser | Select-Object Name, Enabled, LastLogon | Format-Table -AutoSize | Out-String)
  $admins = (Get-LocalGroupMember -Group "Administrators" | Select-Object Name, ObjectClass | Format-Table -AutoSize | Out-String)

@"
=== LOCAL USERS ===
$localUsers

=== LOCAL ADMINISTRATORS ===
$admins
"@
}

# --- Processes / Services / Tasks ---
try {
  Get-Process | Sort-Object CPU -Descending |
    Select-Object -First 200 Name, Id, CPU, WorkingSet64, Path |
    Export-Csv (Join-Path $outDir "processes.csv") -NoTypeInformation -Force
} catch {
  Out-Text "processes.csv" "[error exporting processes]"
}

try {
  Get-CimInstance Win32_Service |
    Select-Object Name, DisplayName, State, StartMode, StartName, PathName |
    Export-Csv (Join-Path $outDir "services.csv") -NoTypeInformation -Force
} catch {
  Out-Text "services.csv" "[error exporting services]"
}

try {
  Get-ScheduledTask |
    Select-Object TaskName, TaskPath, State, Author |
    Export-Csv (Join-Path $outDir "scheduled_tasks.csv") -NoTypeInformation -Force
} catch {
  Out-Text "scheduled_tasks.csv" "[error exporting scheduled tasks]"
}

# --- Recent Security events (best-effort; depends on log settings) ---
Try-Run "recent_security_events.txt" {
  $events = Get-WinEvent -FilterHashtable @{ LogName='Security'; Id=4624,4625,4720,4722,4723,4724,4725,4726,4732,4733 } -MaxEvents 200
  $events | Select-Object TimeCreated, Id, ProviderName, Message | Format-List | Out-String
}

# --- Summary (quick glance) ---
Try-Run "summary.txt" {
  $profiles = Get-NetFirewallProfile
  $fw = $profiles | ForEach-Object { "$($_.Name)=$($_.Enabled)" } | Sort-Object
  $listen = (Get-NetTCPConnection -State Listen | Select-Object -ExpandProperty LocalPort | Sort-Object -Unique) -join ", "
  $admins = (Get-LocalGroupMember -Group "Administrators" | Select-Object -ExpandProperty Name) -join ", "

@"
Host: $env:COMPUTERNAME
Time: $(Get-Date)
Firewall: $($fw -join " | ")
Listening TCP Ports: $listen
Local Admins: $admins

Next steps:
- If scoring service breaks when you tighten firewall, whitelist only what is required.
- Review services.csv + scheduled_tasks.csv for anything weird (random names, temp paths, unsigned tools).
- Use TCPView/ProcExp for anything that looks sus.
"@
}

Write-Host "Done. Output folder: $outDir"
