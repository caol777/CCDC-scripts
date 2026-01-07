# wininfo.ps1
# Readable inventory + evidence, saved in CURRENT directory into a folder.

$hostname  = $env:COMPUTERNAME
$timestamp = Get-Date -Format "yyyy-MM-dd_HHmmss"

$outDir  = Join-Path (Get-Location) ("Inventory_{0}_{1}" -f $hostname, $timestamp)
$outFile = Join-Path $outDir "inventory.txt"
New-Item -ItemType Directory -Path $outDir -Force | Out-Null

function Add([string]$line = "") {
    $line | Out-File -FilePath $outFile -Append -Encoding utf8
}

# --- OS + IPs ---
$os = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue

$ips = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
    Where-Object { $_.IPAddress -notlike "169.254*" -and $_.IPAddress -ne "127.0.0.1" } |
    Sort-Object InterfaceAlias,IPAddress

# --- Listening ports with PID ---
$tcpListen = @(Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue |
    Select-Object LocalPort, OwningProcess)

$udpListen = @(Get-NetUDPEndpoint -ErrorAction SilentlyContinue |
    Select-Object LocalPort, OwningProcess)

$listen = @()
foreach ($t in $tcpListen) { $listen += [pscustomobject]@{ Proto = "tcp"; Port = [int]$t.LocalPort; PID = [int]$t.OwningProcess } }
foreach ($u in $udpListen) { $listen += [pscustomobject]@{ Proto = "udp"; Port = [int]$u.LocalPort; PID = [int]$u.OwningProcess } }
$listen = $listen | Sort-Object Proto,Port,PID -Unique

# --- PID -> process name ---
$procMap = @{}
Get-Process -ErrorAction SilentlyContinue | ForEach-Object { $procMap[$_.Id] = $_.ProcessName }

# --- PID -> Windows service names (if any) ---
$svcByPid = @{}
Get-CimInstance Win32_Service -ErrorAction SilentlyContinue | ForEach-Object {
    if ($_.ProcessId -and $_.ProcessId -ne 0) {
        if (-not $svcByPid.ContainsKey($_.ProcessId)) { $svcByPid[$_.ProcessId] = @() }
        $svcByPid[$_.ProcessId] += $_.Name
    }
}

# --- Port -> friendly service labels (readable like your friend's output) ---
$portMap = @{
    22   = "Remote (ssh)"
    80   = "HTTP"
    443  = "HTTPS"
    3389 = "Remote (rdp)"
    445  = "File Share (smb)"
    135  = "RPC"
    53   = "DNS"
    389  = "Domain Controller (ldap)"
    636  = "Domain Controller (ldaps)"
    88   = "Domain Controller (kerberos)"
    1433 = "Database (mssql)"
    3306 = "Database (mysql)"
    5432 = "Database (postgres)"
    25   = "Mail (smtp)"
    110  = "Mail (pop3)"
    143  = "Mail (imap)"
    587  = "Mail (submission)"
    5985 = "Remote (winrm)"
    5986 = "Remote (winrm-https)"
}

# --- Build Services line ---
$serviceLabels = New-Object System.Collections.Generic.HashSet[string]
foreach ($row in $listen) {
    if ($portMap.ContainsKey($row.Port)) {
        [void]$serviceLabels.Add($portMap[$row.Port])
    }
}

# --- Write report ---
Add "Inventory Report"
Add ("Generated: {0}" -f (Get-Date))
Add ""

Add "Host:"
Add ("  {0}" -f $hostname)
Add ""

Add "Operating System:"
if ($os) {
    Add ("  {0} (Version {1}, Build {2})" -f $os.Caption, $os.Version, $os.BuildNumber)
} else {
    Add "  (Unable to read OS info)"
}
Add ""

Add "IP Addresses (IPv4):"
if ($ips -and $ips.Count -gt 0) {
    foreach ($ip in $ips) { Add ("  {0}: {1}" -f $ip.InterfaceAlias, $ip.IPAddress) }
} else {
    Add "  (none found)"
}
Add ""

Add "Services (inferred from listening ports):"
if ($serviceLabels.Count -gt 0) {
    Add ("  {0}" -f (($serviceLabels | Sort-Object) -join ", "))
} else {
    Add "  (none mapped - only unmapped/ephemeral ports detected)"
}
Add ""

Add "Required Ports (mapped):"
$mappedRows = $listen | Where-Object { $portMap.ContainsKey($_.Port) } | Sort-Object Port,Proto -Unique
if ($mappedRows) {
    foreach ($m in $mappedRows) {
        Add ("  {0,5}/{1}  -> {2}" -f $m.Port, $m.Proto, $portMap[$m.Port])
    }
} else {
    Add "  (none)"
}
Add ""

Add "Other Listening Ports (unmapped):"
$unmapped = $listen | Where-Object { -not $portMap.ContainsKey($_.Port) } | Sort-Object Port,Proto -Unique
if ($unmapped) {
    foreach ($u in $unmapped) {
        Add ("  {0}/{1}" -f $u.Port, $u.Proto)
    }
} else {
    Add "  (none)"
}
Add ""

Add "Evidence (Listening Port -> Process -> Windows Service):"
if ($listen.Count -eq 0) {
    Add "  (none)"
} else {
    foreach ($row in ($listen | Sort-Object Port,Proto,PID)) {
        $pname = if ($procMap.ContainsKey($row.PID)) { $procMap[$row.PID] } else { "UNKNOWN" }
        $svcs  = if ($svcByPid.ContainsKey($row.PID)) { (($svcByPid[$row.PID] | Sort-Object -Unique) -join ",") } else { "" }

        if ([string]::IsNullOrWhiteSpace($svcs)) {
            Add ("  {0,5}/{1,-3}  PID:{2,-6}  Proc:{3}" -f $row.Port, $row.Proto, $row.PID, $pname)
        } else {
            Add ("  {0,5}/{1,-3}  PID:{2,-6}  Proc:{3,-18}  Svc:{4}" -f $row.Port, $row.Proto, $row.PID, $pname, $svcs)
        }
    }
}
Add ""

Add "Containers:"
$docker = Get-Command docker -ErrorAction SilentlyContinue
if ($docker) {
    Add "  Docker detected:"
    & docker ps -a --format '  {{.Names}} | {{.Image}} | {{.Status}} | {{.Ports}}' 2>$null |
        Out-File -FilePath $outFile -Append -Encoding utf8
} else {
    Add "  Docker not installed."
}
Add ""
Add ("Saved to: {0}" -f $outFile)

Write-Host "Saved: $outFile"
