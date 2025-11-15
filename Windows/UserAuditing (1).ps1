#predefined list (change for each comp)
$acclist = @("jmoney", "plinktern") | ForEach-Object { $_.Trim().ToLower() }
$acc = Get-LocalUser | Select-Object -ExpandProperty Name | ForEach-Object { $_.Trim().ToLower() }

foreach ($user in $acc) {
    if ($user -notin $acclist) {
        net user $user /active:no
    } 
}