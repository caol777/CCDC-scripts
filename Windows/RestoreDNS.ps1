$BackupPath = "C:\DNS_Backup"
$ZoneList = Import-Csv "$BackupPath\ZoneList.csv"
$MaxTries = 30
$TryCount = 0
$Success = $false

Write-Host "--- PHASE 0: LOG & ROLE HEALING ---" -ForegroundColor Cyan
Write-Host "  Resetting Event Tracing..."
Get-Service EventLog | Restart-Service -Force
wevtutil cl System; wevtutil cl "DNS Server"; wevtutil cl "Directory Service"

$RequiredFeatures = @("DNS", "AD-Domain-Services")
foreach ($Feat in $RequiredFeatures) {
    if ((Get-WindowsFeature $Feat).InstallState -ne "Installed") {
        Install-WindowsFeature $Feat -IncludeManagementTools
    }
}

Get-NetIPInterface -AddressFamily IPv4 | Set-DnsClientServerAddress -ServerAddresses ("127.0.0.1")

Write-Host "--- PHASE 1: SECURITY & CONFIG ---" -ForegroundColor Cyan
Set-Service W32Time -StartupType Automatic
Start-Service W32Time -ErrorAction SilentlyContinue
w32tm /resync /force | Out-Null
klist purge -li 0x3e7 # Critical for System-level auth
Restart-Service KDC -Force

if (Test-Path "$BackupPath\DNS_Settings.reg") { reg import "$BackupPath\DNS_Settings.reg" }

Write-Host "--- PHASE 2: DATA RESET ---" -ForegroundColor Cyan
Stop-Service DNS, Netlogon -Force 
Copy-Item "$BackupPath\*.dns.bak" "C:\Windows\System32\dns"
foreach ($Row in $ZoneList) {
    $Zone = $Row.ZoneName
    if ($Zone -eq "." -or $Zone -eq "TrustAnchors") { continue }
    $RealFile = "C:\Windows\System32\dns\$Zone.dns"
    if (Test-Path "$RealFile.bak") { Move-Item "$RealFile.bak" $RealFile -Force }
    dnscmd /ZoneAdd $Zone /Primary /file "$Zone.dns" /load | Out-Null
}

Write-Host "--- PHASE 3: BREAKING DEADLOCKS ---" -ForegroundColor Cyan
Start-Service DNS, Netlogon
while ((Get-Service Netlogon).Status -ne 'Running') { Start-Sleep -Seconds 1 }

ipconfig /registerdns
nltest /dsregdns 
Restart-Service Netlogon -Force

Write-Host "--- PHASE 4: AD CONVERSION ---" -ForegroundColor Cyan


while ($TryCount -lt $MaxTries -and -not $Success) {
    $TryCount++
    Write-Host "Attempting to Migrate to AD..." -ForegroundColor Yellow
    foreach ($Row in $ZoneList) {
        $Zone = $Row.ZoneName
        if ($Zone -eq "." -or $Zone -eq "TrustAnchors") { continue }
        dnscmd /ZoneResetType $Zone /dsprimary | Out-Null
    }
    
    $CheckZone = ($ZoneList | Where-Object { $_.ZoneName -ne "TrustAnchors" })[0].ZoneName
    $Status = Get-DnsServerZone -Name $CheckZone -ErrorAction SilentlyContinue
    if ($Status.IsDsIntegrated -eq $true) {
        $Success = $true
        Write-Host " [SUCCESS] Integrated!" -ForegroundColor Green
    } else {
        if ($TryCount -eq 15) { 
            klist purge -li 0x3e7
            Restart-Service KDC, Netlogon, DNS -Force 
            nltest /dsregdns
        }
        Start-Sleep -Seconds 10
    }
}
