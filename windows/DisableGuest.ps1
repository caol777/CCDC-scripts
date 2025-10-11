# Disable the Guest account
$Guest = Get-LocalUser -Name Guest -ErrorAction SilentlyContinue
if($Guest){
    Disable-LocalUser -Name Guest
    Write-Host "Guest account disabled."
} else {
    Write-Host "Guest account not found."
}
