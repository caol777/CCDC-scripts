$BackupPath = "C:\AD_Backup"
$IFMPath = "$BackupPath\AD_Database"
$UserCSV = "$BackupPath\UserSnapshot.csv"
$GPOPath = "$BackupPath\GPOs"

$SafeMode = Test-Path "HKLM:\System\CurrentControlSet\Control\SafeBoot\Option"

if ($SafeMode) {
    Write-Host "[!] DSRM DETECTED: Seeding database and providing manual guide." -ForegroundColor Yellow
    Copy-Item -Path "$IFMPath\Active Directory\ntds.dit" -Destination "C:\Windows\NTDS\ntds.dit" -Force
    
    Write-Host "STEP 1: Database file seeded to C:\Windows\NTDS\ntds.dit" -ForegroundColor Cyan
    Write-Host "STEP 2: Run this exact command to restore the GREAT.CRETACEOUS domain:" -ForegroundColor Cyan
    Write-Host "ntdsutil `"activate instance ntds`" `"authoritative restore`" `"restore subtree \`"DC=GREAT,DC=CRETACEOUS\`"`" quit quit" "(Change to comp specific Domain Name)"
    Write-Host "STEP 3: bcdedit /deletevalue {current} safeboot && Restart-Computer" -ForegroundColor Cyan
} 
else {
    Write-Host "[*] NORMAL MODE DETECTED: Proceeding with Surgical Fixes." -ForegroundColor Yellow
    Write-Host "------------------------------------------------------------"

  
    Write-Host "[*] STEP 1: Syncing System Time..." -ForegroundColor Cyan
    Set-Date -Date "01/06/2026 18:10" 

    if (Test-Path $GPOPath) {
        Write-Host "[*] STEP 2: Importing GPO Exports..." -ForegroundColor Cyan
        Get-ChildItem $GPOPath -Directory | ForEach-Object {
            $GUID = $_.Name
            Write-Host " Attempting to import GPO folder: $GUID" -ForegroundColor Gray
            
            try {
                Import-GPO -BackupId $GUID -Path $GPOPath -TargetName $GUID -CreateIfNeeded -ErrorAction Stop | Out-Null
                Write-Host " [+] Successfully imported GUID $GUID" -ForegroundColor Green
            } catch {
                Write-Host " [!] Failed to import $GUID. Error: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }

    if (Test-Path $UserCSV) {
        Write-Host "[*] STEP 3: Reconstructing Users from CSV..." -ForegroundColor Cyan
        $Users = Import-Csv -Path $UserCSV
        foreach ($U in $Users) {
            if (-not (Get-ADUser -Filter "SamAccountName -eq '$($U.SamAccountName)'" -ErrorAction SilentlyContinue)) {
                Write-Host " Creating user: $($U.SamAccountName)" -ForegroundColor Gray
                $OU = $U.DistinguishedName.Substring($U.DistinguishedName.IndexOf("OU="))
                $SecurePass = ConvertTo-SecureString "P@ssword123!" -AsPlainText -Force
                New-ADUser -Name $U.SamAccountName -SamAccountName $U.SamAccountName -Path $OU -AccountPassword $SecurePass -Enabled $true
            }
        }
    }

    Write-Host "`n--- Reconstruction Complete. Please run 'gpupdate /force' ---" -ForegroundColor Green
}
