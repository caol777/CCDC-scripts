#ensure that kernel object auditing is on
auditpol /set /subcategory:"Kernel Object" /success:enable /failure:enable
#output the result
auditpol /get /subcategory:"Kernel Object"
#quickly get current user
$s = $env:USERNAME
# get the necessary events & output to file
Get-WinEvent -Path "C:\Windows\System32\Winevt\Logs\Security.evtx" -FilterXPath "*[System[(EventID=4663)]]" `
|Select-Object -ExpandProperty message |ForEach-Object { $_; "`n----------------------------------------------------------`n" } `
| Out-File -FilePath "C:\Users\$s\Desktop\4663.txt"

Get-WinEvent -Path "C:\Windows\System32\Winevt\Logs\Security.evtx" -FilterXPath "*[System[(EventID=4688)]]" `
|Select-Object -ExpandProperty message | ForEach-Object { $_; "`n----------------------------------------------------------`n" } `
|Out-File -FilePath "C:\Users\$s\Desktop\4688.txt"




# 1. access log file and scan with FilterXPath(event id's 4663 and 4688)
# 2. output to screen and review manually? -Files
# 3. Parse files for useful information -Manually?
# 3. path: %SystemRoot%\System32\Winevt\Logs\Security.evtx