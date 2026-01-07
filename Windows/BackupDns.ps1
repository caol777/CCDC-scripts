$BackupPath = "C:\DNS_Backup"
if (Test-Path $BackupPath) { Remove-Item $BackupPath -Recurse -Force }
New-Item $BackupPath -ItemType Directory -Force | Out-Null

Get-DnsServerZone | Select-Object ZoneName, ZoneType | Export-Csv "$BackupPath\ZoneList.csv"

Write-Host "Exporting Zones..." -ForegroundColor Cyan
Get-DnsServerZone | ForEach-Object {
    $Zone = $_.ZoneName
    dnscmd /ZoneExport $Zone "$Zone.dns.bak" | Out-Null
}
reg export "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\DNS\Parameters" C:\DNS_Backup\DNS_Settings.reg

Start-Sleep -Seconds 2
Move-Item "C:\Windows\System32\dns\*.dns.bak" $BackupPath -Force

Write-Host "Backup Complete. Files secured in $BackupPath" -ForegroundColor Green
 
