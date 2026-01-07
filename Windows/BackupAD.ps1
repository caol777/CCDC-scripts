bcdedit /set safeboot dsrepair
ntdsutil "set dsrm password" "reset password on server null" q q

$BackupPath = "C:\AD_Backup"
if (Test-Path $BackupPath) { Remove-Item $BackupPath -Recurse -Force }
New-Item $BackupPath -ItemType Directory -Force | Out-Null

Write-Host "--- PHASE 1: DATABASE EXPORT (IFM) ---" -ForegroundColor Cyan
Write-Host "Exporting AD Database and Registry Hives..." -ForegroundColor Yellow

ntdsutil "ac in ntds" "ifm" "create full $BackupPath\AD_Database" q q | Out-Null

Write-Host "--- PHASE 2: GROUP POLICY EXPORT ---" -ForegroundColor Cyan
Write-Host "Backing up all GPOs..." -ForegroundColor Yellow
$GPOPath = New-Item "$BackupPath\GPOs" -ItemType Directory -Force
Backup-Gpo -All -Path $GPOPath | Out-Null

Write-Host "--- PHASE 3: AD OBJECT SNAPSHOT (CSV) ---" -ForegroundColor Cyan
Write-Host "Exporting User and Group lists for quick reference..." -ForegroundColor Yellow
Get-ADUser -Filter * -Properties MemberOf | Export-Csv "$BackupPath\UserSnapshot.csv" -NoTypeInformation
Get-ADGroup -Filter * | Export-Csv "$BackupPath\GroupSnapshot.csv" -NoTypeInformation

Write-Host "--- Backup Complete! Location: $BackupPath ---" -ForegroundColor Green
Write-Host "REMINDER: Move this folder to a USB or secondary drive immediately!" -ForegroundColor Red
