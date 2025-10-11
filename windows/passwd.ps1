# SCRIPT TO RESET ALL LOCAL USER PASSWORDS

# --- WARNING ---
Write-Host "🚨 WARNING: This script will reset the password for all enabled local users except 'Administrator' and 'Guest'." -ForegroundColor Red
Write-Host "This is a destructive action. Only proceed if you are an authorized administrator in a controlled environment." -ForegroundColor Yellow
Read-Host "Press Enter to continue or CTRL+C to abort."

# --- Get the new password securely ---
$newPassword = Read-Host -AsSecureString "Enter the new password for all users"

# --- Define accounts to exclude ---
$excludedUsers = @("Administrator", "Guest", "DefaultAccount", "WDAGUtilityAccount")

try {
    # Get all local users, filter out the excluded and disabled ones
    $users = Get-LocalUser | Where-Object { ($_.Enabled -eq $true) -and ($_.Name -notin $excludedUsers) }

    if ($null -eq $users) {
        Write-Host "No users found to process." -ForegroundColor Green
        exit
    }

    # Loop through each user and set the new password
    foreach ($user in $users) {
        try {
            Write-Host "Setting password for user: $($user.Name)..." -ForegroundColor Cyan
            $user.SetPassword($newPassword)
            Write-Host "Successfully changed password for $($user.Name)." -ForegroundColor Green
        }
        catch {
            Write-Host "Failed to change password for $($user.Name). Error: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    Write-Host "Script finished."
}
catch {
    Write-Host "An unexpected error occurred: $($_.Exception.Message)" -ForegroundColor Red
}
