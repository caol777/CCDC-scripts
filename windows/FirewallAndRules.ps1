#set initial firewall state, block all traffic
Set-NetFirewallProfile -Profile Domain,Private,Public `
-DefaultInboundAction Block -DefaultOutboundAction Block -EnableStealthModeForIPsec true `
-LogAllowed True -LogBlocked True -AllowUserApps False -AllowUserPorts False `
-AllowUnicastResponseToMulticast False -AllowInboundRules False -AllowLocalFirewallRules False `
-AllowLocalIPsecRules False

#kill all pre-existing firewall rules
Remove-NetFirewallRule

#set rules for scored services (placeholder examples, change as competition requires):
New-NetFirewallRule -DisplayName "Remote Desktop Protocol" -Direction Inbound -Action Allow -LocalPort 3389

New-NetFirewallRule -DisplayName "HTTPS" -Direction Outbound -Protocol TCP -Action Allow -RemotePort 443

