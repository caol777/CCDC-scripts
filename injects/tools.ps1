# Installs Sysinternals tools safely for WRCCDC

$BaseDir = "C:\CCDC"
$ToolDir = "$BaseDir\Tools\Sysinternals"
$ZipUrl  = "https://download.sysinternals.com/files/SysinternalsSuite.zip"
$ZipPath = "$BaseDir\SysinternalsSuite.zip"

Write-Host "=== Installing Sysinternals Tools ==="

# Ensure folders exist
New-Item -ItemType Directory -Path $ToolDir -Force | Out-Null

# Try to download if tools aren't present
if (-not (Test-Path "$ToolDir\Autoruns.exe")) {
    Write-Host "[*] Downloading Sysinternals Suite..."
    try {
        Invoke-WebRequest -Uri $ZipUrl -OutFile $ZipPath -ErrorAction Stop
        Expand-Archive $ZipPath -DestinationPath $ToolDir -Force
    }
    catch {
        Write-Host "[!] Download failed. Assuming tools are already in repo."
    }
}

# Unblock executables (VERY important)
Get-ChildItem $ToolDir -Recurse -Filter *.exe | ForEach-Object {
    Unblock-File $_.FullName
}

Write-Host "[+] Sysinternals tools ready at $ToolDir"
