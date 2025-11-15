<#
.SYNOPSIS
CCDC-style WinRM hardening script
- Configures WinRM to use HTTPS
- Restricts firewall access to specific IP(s)
- Limits access to authorized users
- Enables auditing
- Sets session timeouts
#>

# --- Variables ---
$hostname = "Host01.ccdc.local"          # Change to your host FQDN if needed
$allowedIP = "10.0.0.1"                  # Change to your DC or trusted host IP
$maxTimeoutMs = 420000                   # 7 minutes

# --- 1. Create/Get a self-signed certificate for HTTPS ---
$cert = Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object { $_.Subject -like "*$hostname*" }
if (-not $cert) {
    $cert = New-SelfSignedCertificate -DnsName $hostname -CertStoreLocation Cert:\LocalMachine\My
}

# --- 2. Configure WinRM listener to use HTTPS ---
# Remove any HTTP listener
Get-ChildItem WSMan:\localhost\Listener | Where-Object { $_.Keys -eq "Transport=HTTP" } | Remove-Item -Force

# Create HTTPS listener if it doesn't exist
$httpsListener = Get-ChildItem WSMan:\localhost\Listener | Where-Object { $_.Keys -eq "Transport=HTTPS" }
if (-not $httpsListener) {
    winrm create winrm/config/Listener?Address=*+Transport=HTTPS "@{Hostname='$hostname';CertificateThumbprint='$($cert.Thumbprint)'}"
}

# --- 3. Restrict WinRM to specific IP using Windows Firewall ---
# Remove existing rules (optional, avoid duplicates)
Get-NetFirewallRule -DisplayName "Allow WinRM HTTPS from DC" -ErrorAction SilentlyContinue | Remove-NetFirewallRule -ErrorAction SilentlyContinue

# Add rule to allow WinRM HTTPS from allowed IP
New-NetFirewallRule -Name "Allow WinRM HTTPS" `
    -DisplayName "Allow WinRM HTTPS from DC" `
    -Protocol TCP -LocalPort 5986 -RemoteAddress $allowedIP `
    -Action Allow

# --- 4. Restrict access to authorized users only ---
# Launch SDDL GUI to remove Everyone and allow only admins or specific groups
Set-PSSessionConfiguration -Name Microsoft.PowerShell -ShowSecurityDescriptorUI

# --- 5. Enable auditing for WinRM access ---
auditpol /set /subcategory:"Logon" /success:enable /failure:enable

# --- 6. Set session timeout ---
winrm set winrm/config '@{MaxTimeoutms="' + $maxTimeoutMs + '"}'

# --- 7. Disable all unnecessary services ---
# Only do if strictly needed; leave WinRM enabled
# Example: disable FTP, SMB, HTTP services if running
# Stop-Service -Name 'FTPSVC','W3SVC','SMBServer' -ErrorAction SilentlyContinue
# Set-Service -Name 'FTPSVC','W3SVC','SMBServer' -StartupType Disabled -ErrorAction SilentlyContinue

# --- 8. Validation message ---
Write-Host "WinRM hardening complete."
Write-Host "Use Test-WsMan -ComputerName $hostname -UseSSL from trusted host to verify connectivity."
