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

#Get Process Associated
Get-NetTCPConnection -State Listen | ForEach-Object {
    $ProcessID = $_.OwningProcess
    $Process = Get-Process -Id $ProcessID -ErrorAction SilentlyContinue
    if ($Process) {
        [PSCustomObject]@{
            LocalAddress   = $_.LocalAddress
            LocalPort      = $_.LocalPort
            RemoteAddress  = $_.RemoteAddress
            RemotePort     = $_.RemotePort
            State          = $_.State
            ProcessName    = $Process.ProcessName
            ProcessId      = $ProcessID
        }
    }
    else {
        [PSCustomObject]@{
            LocalAddress   = $_.LocalAddress
            LocalPort      = $_.LocalPort
            RemoteAddress  = $_.RemoteAddress
            RemotePort     = $_.RemotePort
            State          = $_.State
            ProcessName    = "Unknown"
            ProcessId      = $ProcessID
        }
    }
} | Format-Table #For better reading.
