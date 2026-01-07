# WRCCDC_Firewall_Baseline.ps1
# Goal: scoring-safe baseline (block inbound by default, allow outbound)

# ======= EDIT THESE =======
$AllowedInboundTCP = @(80, 443)       # Add your service ports here
$AllowedInboundUDP = @()             # Example: @(53,123) if the BOX provides DNS/NTP (rare)
$EnableRDP = $true
$RestrictRDP = $true
$RdpAllowedRemoteAddresses = @("10.0.0.0/8","172.16.0.0/12","192.168.0.0/16") # adjust if needed
$LogFolder = "$env:SystemRoot\System32\LogFiles\Firewall"
# ===========================

Write-Host "=== WRCCDC Firewall Baseline ===" -ForegroundColor Cyan

# 1) Backup current firewall policy
$ts = Get-Date -Format "yyyyMMdd_HHmmss"
$backupPath = "C:\fwbackup_$ts.wfw"
Write-Host "[1/7] Exporting firewall policy to $backupPath"
netsh advfirewall export $backupPath | Out-Null

# 2) Make sure firewall is ON + set safe defaults
Write-Host "[2/7] Enabling firewall + setting defaults (Inbound=Block, Outbound=Allow)"
Set-NetFirewallProfile -Profile Domain,Private,Public `
  -Enabled True `
  -DefaultInboundAction Block `
  -DefaultOutboundAction Allow `
  -AllowInboundRules True `
  -AllowLocalFirewallRules True `
  -AllowUnicastResponseToMulticast False `
  -NotifyOnListen True | Out-Null

# 3) Logging (helps you prove what happened + troubleshoot)
Write-Host "[3/7] Configuring firewall logging"
New-Item -ItemType Directory -Path $LogFolder -Force | Out-Null
Set-NetFirewallProfile -Profile Domain,Private,Public `
  -LogAllowed True `
  -LogBlocked True `
  -LogMaxSizeKilobytes 32767 `
  -LogFileName "$LogFolder\pfirewall.log" | Out-Null

# 4) (Optional) Clean up only the rules WE create (so reruns don't duplicate)
Write-Host "[4/7] Removing old WRCCDC_* rules (if any)"
Get-NetFirewallRule -DisplayName "WRCCDC_*" -ErrorAction SilentlyContinue | Remove-NetFirewallRule -ErrorAction SilentlyContinue

# 5) Allow inbound ports you specify
Write-Host "[5/7] Creating inbound allow rules for required services"

foreach ($p in $AllowedInboundTCP) {
  New-NetFirewallRule `
    -DisplayName "WRCCDC_TCP_In_$p" `
    -Direction Inbound -Action Allow -Enabled True `
    -Protocol TCP -LocalPort $p `
    -Profile Domain,Private,Public `
    -EdgeTraversalPolicy Block | Out-Null
}

foreach ($p in $AllowedInboundUDP) {
  New-NetFirewallRule `
    -DisplayName "WRCCDC_UDP_In_$p" `
    -Direction Inbound -Action Allow -Enabled True `
    -Protocol UDP -LocalPort $p `
    -Profile Domain,Private,Public `
    -EdgeTraversalPolicy Block | Out-Null
}

# 6) RDP handling (optional, recommended to restrict if you keep it)
if ($EnableRDP) {
  Write-Host "[6/7] RDP enabled: allowing TCP/3389"
  if ($RestrictRDP -and $RdpAllowedRemoteAddresses.Count -gt 0) {
    New-NetFirewallRule `
      -DisplayName "WRCCDC_RDP_3389_Restricted" `
      -Direction Inbound -Action Allow -Enabled True `
      -Protocol TCP -LocalPort 3389 `
      -RemoteAddress $RdpAllowedRemoteAddresses `
      -Profile Domain,Private,Public | Out-Null
  } else {
    New-NetFirewallRule `
      -DisplayName "WRCCDC_RDP_3389" `
      -Direction Inbound -Action Allow -Enabled True `
      -Protocol TCP -LocalPort 3389 `
      -Profile Domain,Private,Public | Out-Null
  }
} else {
  Write-Host "[6/7] RDP disabled: blocking TCP/3389 + turning off Remote Desktop"
  # Firewall block
  New-NetFirewallRule `
    -DisplayName "WRCCDC_Block_RDP_3389" `
    -Direction Inbound -Action Block -Enabled True `
    -Protocol TCP -LocalPort 3389 `
    -Profile Domain,Private,Public | Out-Null

  # Turn off RDP at OS level
  Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 1 -Force
  Disable-NetFirewallRule -DisplayGroup "Remote Desktop" -ErrorAction SilentlyContinue | Out-Null
}

# 7) Quick report
Write-Host "[7/7] Done. Current profile defaults:"
Get-NetFirewallProfile | Select-Object Name, Enabled, DefaultInboundAction, DefaultOutboundAction, LogAllowed, LogBlocked, LogFileName | Format-Table -AutoSize

Write-Host "`nRules created:" -ForegroundColor Green
Get-NetFirewallRule -DisplayName "WRCCDC_*" |
  Select-Object DisplayName, Direction, Action, Enabled |
  Format-Table -AutoSize

Write-Host "`nTip: If scoring breaks, add the needed port to AllowedInboundTCP and rerun." -ForegroundColor Yellow
