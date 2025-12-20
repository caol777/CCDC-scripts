$acc = Get-LocalUser | Select-Object -ExpandProperty Name | ForEach-Object { $_.Trim().ToLower() }

# store results
$results = @()

foreach ($user in $acc) {
    Write-Host "`nSet password for: $user"
    $PasswordSecure = Read-Host "Enter the new password" -AsSecureString

    # set password
    Set-LocalUser -Name $user -Password $PasswordSecure

    # convert securestring → plain text so it can be shown
    $PasswordPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($PasswordSecure)
    )

    # save the pair
    $results += [PSCustomObject]@{
        User     = $user
        Password = $PasswordPlain
    }
}

# print all results
Write-Host "`n=== PASSWORD SUMMARY ===`n"
$results | Format-Table -AutoSize
