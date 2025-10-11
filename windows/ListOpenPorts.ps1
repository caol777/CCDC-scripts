# Use Get-NetTCPConnection to list open ports and listening processes

# Get all listening TCP connections
Get-NetTCPConnection -State Listen

# You can also filter by local port, remote address, etc.
# Example:  Get-NetTCPConnection -State Listen -LocalPort 80

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
