#create backup
netsh advfirewall export "C:\fwbackup.wfw"

#set initial firewall state, block all traffic
Set-NetFirewallProfile -Profile Domain,Private,Public `
-DefaultInboundAction Block -DefaultOutboundAction Block -EnableStealthModeForIPsec true `
-LogAllowed True -LogBlocked True -LogIgnored True -AllowUserApps False -AllowUserPorts False `
-AllowUnicastResponseToMulticast False -AllowInboundRules True -AllowLocalFirewallRules True `
-AllowLocalIPsecRules False

# WIP CODE TO CREATE CRITICAL RULES THAT DONT EXIST, NOT CURRENTLY FUCTIONING PROPERLY
#set critical rules
# $criticalRules = @(
#     [PSCustomObject]@{Direction='Inbound'; Protocol='TCP'; LocalPort=3389; Action="Allow"},
#     [PSCustomObject]@{Direction='Outbound'; Protocol='UDP'; RemotePort=53; Action="Allow"},
#     [PSCustomObject]@{Direction='Outbound'; Protocol='TCP'; RemotePort=53; Action="Allow"},
#     [PSCustomObject]@{Direction='Outbound'; Protocol='UDP'; LocalPort=68; RemotePort=67; Action="Allow"},
#     [PSCustomObject]@{Direction='Inbound'; Protocol='UDP'; LocalPort=67; RemotePort=68; Action="Allow"},
#     [PSCustomObject]@{Direction='Outbound'; Protocol='UDP'; RemotePort=123; Action="Allow"},
#     [PSCustomObject]@{Direction='Outbound'; Protocol='TCP'; RemotePort=443; Action="Allow"},
#     [PSCustomObject]@{Direction='Inbound'; Protocol='TCP'; LocalPort=445; Action="Allow"},
#     [PSCustomObject]@{Direction='Inbound'; Protocol='TCP'; LocalPort=139; Action="Allow"},
#     [PSCustomObject]@{Direction='Inbound'; Protocol='TCP'; LocalPort=80; Action="Allow"},
#     [PSCustomObject]@{Direction='Inbound'; Protocol='TCP'; LocalPort=443; Action="Allow"},
#     [PSCustomObject]@{Direction='Inbound'; Protocol='TCP'; LocalPort=135; Action="Allow"},
#     [PSCustomObject]@{Direction='Inbound'; Protocol='TCP'; LocalPort="49152-65535"; Action="Allow"},
#     [PSCustomObject]@{Direction='Inbound'; Protocol='TCP'; LocalPort=389; Action="Allow"},
#     [PSCustomObject]@{Direction='Inbound'; Protocol='TCP'; LocalPort=636; Action="Allow"},
#     [PSCustomObject]@{Direction='Inbound'; Protocol='TCP'; LocalPort=88; Action="Allow"},
#     [PSCustomObject]@{Direction='Inbound'; Protocol='UDP'; LocalPort=88; Action="Allow"},
#     [PSCustomObject]@{Direction='Inbound'; Protocol="Any";LocalAddress=127.0.0.1; Action="Allow"},
#     [PSCustomObject]@{Direction='Outbound'; Protocol="Any"; LocalAddress=127.0.0.1; Action="Allow"}
    
# )

# foreach ($rule in $criticalRules) {

#     # Auto-generate DisplayName if missing
#     if (-not $rule.PSObject.Properties.Match("DisplayName") -or -not $rule.DisplayName) {
#         $rule | Add-Member -NotePropertyName DisplayName -NotePropertyValue `
#             "AutoRule_$($rule.Direction)_$($rule.Protocol)_$($rule.LocalPort)" -Force
#     }

#     # Check if the rule already exists
#     $exists = Get-NetFirewallPortFilter | Where-Object {
#     $_.Direction -eq $rule.Direction -and
#     ($rule.Protocol -eq "Any" -or $_.Protocol -eq $rule.Protocol) -and
#     (
#         ($rule.LocalPort  -and $_.LocalPort  -eq $rule.LocalPort) -or
#         ($rule.RemotePort -and $_.RemotePort -eq $rule.RemotePort) -or
#         (-not $rule.LocalPort -and -not $rule.RemotePort)
#     )
# }


#     # Only create the rule if it doesn't exist
#     if (-not $exists) {
#         New-NetFirewallRule -DisplayName $rule.DisplayName `
#                             -Direction $rule.Direction `
#                             -Protocol $rule.Protocol `
#                             -LocalPort $rule.LocalPort `
#                             -RemotePort $rule.RemotePort `
#                             -Action $rule.Action
#     }
# }


$maliciousPorts = @(
    4444, 1337, 31337, 5555, 6666, 6667, 6668, 6669,
    9001, 12345, 12346, 27374
)

foreach ($p in $maliciousPorts) {
    $PortBlock = Get-NetFirewallRule -DisplayName "Block Malicious Port $p" -ErrorAction SilentlyContinue
    
    if(-not $PortBlock) {
        New-NetFirewallRule -DisplayName "Block Malicious Port $p" `
        -Direction Inbound `
        -Protocol TCP `
        -LocalPort $p `
        -Action Block

        New-NetFirewallRule -DisplayName "Block Malicious Port $p" `
        -Direction Inbound `
        -Protocol UDP `
        -LocalPort $p `
        -Action Block
    
        New-NetFirewallRule -DisplayName "Block Malicious Port $p Outbound" `
        -Direction Outbound `
        -Protocol TCP `
        -RemotePort $p `
        -Action Block

        New-NetFirewallRule -DisplayName "Block Malicious Port $p Outbound" `
        -Direction Outbound `
        -Protocol UDP `
        -RemotePort $p `
        -Action Block
    }
}

# All PIDs
$PIDs = netstat -ano | ForEach-Object {
    $columns = ($_ -split '\s+') | Where-Object { $_ -ne '' }  # remove empty strings
    if ($columns.Length -ge 5 -and $columns[-1] -match '^\d+$') {
        $columns[-1]  # PID is last column
    }
} | Select-Object -Unique


foreach ($processid in $PIDs) {
    try {
        $proc = Get-Process -Id $processid -ErrorAction Stop
        Write-Host "$processid => $($proc.ProcessName)"
    } catch {
        Write-Host "$processid => (process not found)"
    }
}

Set-SmbServerConfiguration -EnableSMB1Protocol $false -Force
Set-SmbServerConfiguration -EnableSMB2Protocol $true -Force
# Block external TCP 445
#New-NetFirewallRule -DisplayName "Block SMB External" -Direction Inbound -Protocol TCP -LocalPort 445 -RemoteAddress "0.0.0.0/0" -Action Block


