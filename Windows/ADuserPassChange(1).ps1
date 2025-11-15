$acc = Get-ADUser -Filter * | Select-Object -ExpandProperty SamAccountName
$skip = @("krbtgt", "DefaultAccount", "Guest", "WDAGUtilityAccount") | ForEach-Object { $_.Trim().ToLower() }

$results = @()

foreach ($user in $acc) {

    # Skip system accounts
    if ($skip -contains $user.ToLower()) {
        Write-Host "Skipping $user"
        continue
    }

    Write-Host "`nSet password for: $user"
    $Password = Read-Host "Enter the new password for $user" -AsSecureString
        
    Set-ADAccountPassword -Identity $user -NewPassword $Password -Reset

    $PasswordPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
    )

    $results += [PSCustomObject]@{
        User     = $user
        Password = $PasswordPlain
    }
}

Write-Host "`n=== PASSWORD SUMMARY ===`n"
$results | Format-Table -AutoSize
