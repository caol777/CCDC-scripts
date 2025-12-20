# ================================
# Config
# ================================
$BaseDir = "C:\Tools\Sysinternals"
$SysmonDir = "$BaseDir\Sysmon"

# ================================
# Create directories
# ================================
New-Item -ItemType Directory -Force -Path $BaseDir | Out-Null
New-Item -ItemType Directory -Force -Path $SysmonDir | Out-Null

# ================================
# Download Sysinternals tools
# ================================
Invoke-WebRequest https://download.sysinternals.com/files/Autoruns.zip        -OutFile "$BaseDir\Autoruns.zip"
Invoke-WebRequest https://download.sysinternals.com/files/TCPView.zip         -OutFile "$BaseDir\TCPView.zip"
Invoke-WebRequest https://download.sysinternals.com/files/ProcessExplorer.zip -OutFile "$BaseDir\ProcessExplorer.zip"
Invoke-WebRequest https://download.sysinternals.com/files/Sysmon.zip          -OutFile "$SysmonDir\Sysmon.zip"

# ================================
# Extract tools
# ================================
Expand-Archive "$BaseDir\Autoruns.zip"        "$BaseDir\Autoruns"        -Force
Expand-Archive "$BaseDir\TCPView.zip"         "$BaseDir\TCPView"         -Force
Expand-Archive "$BaseDir\ProcessExplorer.zip" "$BaseDir\ProcessExplorer" -Force
Expand-Archive "$SysmonDir\Sysmon.zip"        "$SysmonDir"               -Force

# ================================
# Download SwiftOnSecurity Sysmon config
# ================================
Invoke-WebRequest `
https://raw.githubusercontent.com/SwiftOnSecurity/sysmon-config/master/sysmonconfig-export.xml `
-OutFile "$SysmonDir\sysmon-swift.xml"

# ================================
# Enable command-line process auditing
# ================================
reg add HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\System\Audit `
/v ProcessCreationIncludeCmdLine_Enabled /t REG_DWORD /d 1 /f

# ================================
# Install Sysmon with Swift config
# ================================
cd $SysmonDir

if (Test-Path ".\Sysmon64.exe") {
    .\Sysmon64.exe -accepteula -i sysmon-swift.xml
} elseif (Test-Path ".\Sysmon.exe") {
    .\Sysmon.exe -accepteula -i sysmon-swift.xml
} else {
    Write-Error "Sysmon executable not found."
}

# ================================
# Verify service
# ================================
Get-Service Sysmon64 -ErrorAction SilentlyContinue
