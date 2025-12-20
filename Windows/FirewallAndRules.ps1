#create backup
netsh advfirewall export "C:\fwbackup.wfw"

#set initial firewall state, block all traffic
Set-NetFirewallProfile -Profile Domain,Private,Public `
-DefaultInboundAction Block -DefaultOutboundAction Block -EnableStealthModeForIPsec true `
-LogAllowed True -LogBlocked True -LogIgnored True -AllowUserApps False -AllowUserPorts False `
-AllowUnicastResponseToMulticast False -AllowInboundRules True -AllowLocalFirewallRules True `
-AllowLocalIPsecRules False

#kill all pre-existing firewall rules
Remove-NetFirewallRule

#Configure RPC ports
$rpcPath = "HKLM:\Software\Microsoft\Rpc\Internet"

# Create the key if it doesn't exist
if (-not (Test-Path $rpcPath)) {
    New-Item -Path $rpcPath -Force | Out-Null
}

# Set the RPC dynamic port range and enable Internet ports
Set-ItemProperty -Path $rpcPath -Name "Ports" -Value "5000-5100"
Set-ItemProperty -Path $rpcPath -Name "PortsInternetAvailable" -Value "Y"
Set-ItemProperty -Path $rpcPath -Name "UseInternetPorts" -Value "Y"

Write-Host "RPC dynamic ports configured for 5000-5100."

#set rules for scored services (placeholder examples, change as competition requires):
New-NetFirewallRule -Profile Domain -DisplayName "Allow SMB Inbound" -Direction Inbound -Protocol TCP -LocalPort 445 -Action Allow

New-NetFirewallRule -Profile Domain -DisplayName "Allow Web Traffic" -Direction Inbound -Protocol TCP -LocalPort 80,443 -Action Allow

New-NetFirewallRule -Profile Domain -DisplayName "Allow NTP Outbound" -Direction Outbound -Protocol UDP -RemotePort 123 -Action Allow

New-NetFirewallRule -Profile Domain -DisplayName "Allow DNS Outbound UDP"  -Direction Outbound -Protocol UDP -RemotePort 53 -Action Allow
New-NetFirewallRule -Profile Domain -DisplayName "Allow DNS Outbound TCP"  -Direction Outbound -Protocol TCP -RemotePort 53 -Action Allow
New-NetFirewallRule -Profile Domain -DisplayName "Allow DNS Inbound UDP"  -Direction Inbound -Protocol UDP -LocalPort 53 -Action Allow
New-NetFirewallRule -Profile Domain -DisplayName "Allow DNS Inbound TCP" -Direction Inbound -Protocol TCP -LocalPort 53 -Action Allow

New-NetFirewallRule -Profile Domain -DisplayName "Allow RPC Endpoint Mapper" -Direction Inbound -Protocol TCP -LocalPort 135 -Action Allow
New-NetFirewallRule -Profile Domain -DisplayName "Allow RPC Dynamic Ports"  -Direction Inbound -Protocol TCP -LocalPort 5000-5100 -Action Allow

New-NetFirewallRule -Profile Domain -DisplayName "Allow SMB Outbound" -Direction Outbound -Protocol TCP -RemotePort 445 -Action Allow

New-NetFirewallRule -Profile Domain -DisplayName "Allow Windows Update" -Direction Outbound -Protocol TCP -RemotePort 443 -Action Allow

New-NetFirewallRule -Profile Domain -DisplayName "Keberos PCR TCP" -Direction Inbound -Protocol TCP -LocalPort 464 -Action Allow
New-NetFirewallRule -Profile Domain -DisplayName "Keberos PCR UDP" -Direction Inbound -Protocol UDP -LocalPort 464 -Action Allow


#AD Inbound Rules
New-NetFirewallRule -Profile Domain -DisplayName "ADDC - Echo Request ICMPv4" -Direction Inbound -Protocol ICMPv4 -IcmpType 8 -Action Allow
New-NetFirewallRule -Profile Domain -DisplayName "ADDC - Echo Request ICMPv6" -Direction Inbound -Protocol ICMPv6 -IcmpType 128 -Action Allow
New-NetFirewallRule -Profile Domain -DisplayName "ADDC - LDAP TCP-in" -Direction Inbound -Protocol TCP -LocalPort 389 -Action Allow
New-NetFirewallRule -Profile Domain -DisplayName "ADDC - LDAP UDP-in" -Direction Inbound -Protocol UDP -LocalPort 389 -Action Allow
New-NetFirewallRule -Profile Domain -DisplayName "ADDC - LDAP Global TCP-in" -Direction Inbound -Protocol TCP -LocalPort 3268 -Action Allow
New-NetFirewallRule -Profile Domain -DisplayName "ADDC - NetBIOS Name Resolution" -Direction Inbound -Protocol UDP -LocalPort 138 -Action Allow
New-NetFirewallRule -Profile Domain -DisplayName "ADDC - SAM TCP" -Direction Inbound -Protocol TCP -LocalPort 445 -Action Allow
New-NetFirewallRule -Profile Domain -DisplayName "ADDC - SAM UDP" -Direction Inbound -Protocol UDP -LocalPort 445 -Action Allow
New-NetFirewallRule -Profile Domain -DisplayName "ADDC - LDAPS" -Direction Inbound -Protocol TCP -LocalPort 636 -Action Allow
New-NetFirewallRule -Profile Domain -DisplayName "ADDC - LDAPS" -Direction Inbound -Protocol TCP -LocalPort 3269 -Action Allow
New-NetFirewallRule -Profile Domain -DisplayName "ADDC - W32Time" -Direction Inbound -Protocol UDP -LocalPort 123 -Action Allow
New-NetFirewallRule -Profile Domain -DisplayName "ADDC - RPC" -Direction Inbound -Protocol TCP -LocalPort 5000-5100 -Action Allow
New-NetFirewallRule -Profile Domain -DisplayName "ADDC - RPC-EPMAP" -Direction Inbound -Protocol TCP -LocalPort 135 -Action Allow
New-NetFirewallRule -Profile Domain -DisplayName "ADDC - Web Services" -Direction Inbound -Protocol TCP -LocalPort 9389 -Action Allow

#AD Outbound Rules
New-NetFirewallRule -Profile Domain -DisplayName "ADDC - Echo Request ICMPv4" -Direction Outbound -Protocol ICMPv4 -IcmpType 8 -Action Allow
New-NetFirewallRule -Profile Domain -DisplayName "ADDC - Echo Request ICMPv6" -Direction Outbound -Protocol ICMPv6 -IcmpType 128 -Action Allow
New-NetFirewallRule -Profile Domain -DisplayName "ADDC - TCP-out" -Direction Outbound -Protocol TCP -LocalPort Any -Action Allow
New-NetFirewallRule -Profile Domain -DisplayName "ADDC - UDP-out" -Direction Outbound -Protocol UDP -LocalPort Any -Action Allow
New-NetFirewallRule -Profile Domain -DisplayName "ADDC - Web Services TCP-out" -Direction Outbound -Protocol TCP -LocalPort Any -Action Allow

