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

#set rules for scored services (placeholder examples, change as competition requires):
New-NetFirewallRule -DisplayName "Allow DNS Outbound" -Direction Outbound -Protocol UDP -RemotePort 53 -Action Allow

New-NetFirewallRule -DisplayName "Allow RDP" -Direction Inbound -Protocol TCP -LocalPort 3389 -Action Allow

New-NetFirewallRule -DisplayName "Allow SMB" -Direction Inbound -Protocol TCP -LocalPort 445,139 -Action Allow

New-NetFirewallRule -DisplayName "Allow Web Traffic" -Direction Inbound -Protocol TCP -LocalPort 80,443 -Action Allow

New-NetFirewallRule -DisplayName "Allow NTP Outbound" -Direction Outbound -Protocol UDP -RemotePort 123 -Action Allow

New-NetFirewallRule -DisplayName "Allow DHCP Outbound" -Direction Outbound -Protocol UDP -LocalPort 68 -RemotePort 67 -Action Allow
New-NetFirewallRule -DisplayName "Allow DHCP Inbound"  -Direction Inbound  -Protocol UDP -LocalPort 67 -RemotePort 68 -Action Allow

New-NetFirewallRule -DisplayName "Allow DNS Outbound"  -Direction Outbound -Protocol UDP -RemotePort 53 -Action Allow
New-NetFirewallRule -DisplayName "Allow DNS Responses"  -Direction Inbound  -Protocol UDP -LocalPort 49152-65535 -Action Allow
New-NetFirewallRule -DisplayName "Allow DNS TCP Outbound" -Direction Outbound -Protocol TCP -RemotePort 53 -Action Allow
New-NetFirewallRule -DisplayName "Allow DNS TCP Responses" -Direction Inbound -Protocol TCP -LocalPort 49152-65535 -Action Allow

New-NetFirewallRule -DisplayName "Allow RPC Endpoint Mapper" -Direction Inbound -Protocol TCP -LocalPort 135 -Action Allow
New-NetFirewallRule -DisplayName "Allow RPC Dynamic Ports"  -Direction Inbound -Protocol TCP -LocalPort 49152-65535 -Action Allow

New-NetFirewallRule -DisplayName "Allow SMB Outbound" -Direction Outbound -Protocol TCP -RemotePort 445 -Action Allow

New-NetFirewallRule -DisplayName "Allow NTP Responses" -Direction Inbound -Protocol UDP -LocalPort 49152-65535 -Action Allow

New-NetFirewallRule -DisplayName "Allow Windows Update" -Direction Outbound -Protocol TCP -RemotePort 443 -Action Allow

New-NetFirewallRule -DisplayName "Allow Loopback" -Direction Inbound  -LocalAddress 127.0.0.1 -Action Allow
New-NetFirewallRule -DisplayName "Allow Loopback" -Direction Outbound -RemoteAddress 127.0.0.1 -Action Allow
