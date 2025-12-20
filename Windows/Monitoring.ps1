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
