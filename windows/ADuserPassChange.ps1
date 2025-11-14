$acc = Get-ADUser -Filter * | Select-Object -ExpandProperty SamAccountName

$results = @()

foreach ($user in $acc) {
    Write-Host "`nSet password for: $user"
    $Password = Read-Host "Enter the new password for $user" -AsSecureString
    
    Set-ADAccountPassword -Identity $user -NewPassword $Password -Reset

    $PasswordPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
    )

    $results+= [PSCustomObject]@{
        User     = $user
        Password = $PasswordPlain
    }
}

Write-Host "`n=== PASSWORD SUMMARY ===`n"
$results | Format-Table -AutoSize
