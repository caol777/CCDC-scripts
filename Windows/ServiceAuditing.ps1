$servnames = @(
 "AJRouter","ALG","AppIDSvc","Appinfo","AppMgmt","AppReadiness","AppVClient","AppXSvc",
 "AudioEndpointBuilder","Audiosrv","AxInstSV","BFE","BITS","BrokerInfrastructure",
 "bthserv","camsvc","CDPSvc","CertPropSvc","ClipSVC","COMSysApp","CoreMessagingRegistrar",
 "CryptSvc","CscService","DcomLaunch","dcsvc","defragsvc","DeviceAssociationService",
 "DeviceInstall","DevQueryBroker","Dhcp","diagnosticshub.standardcollector.service",
 "DiagTrack","DispBrokerDesktopSvc","DmEnrollmentSvc","dmwappushservice","Dnscache",
 "DoSvc","dot3svc","DPS","DsmSvc","DsSvc","EapHost","edgeupdate","edgeupdatem","EFS",
 "embeddedmode","EntAppSvc","EventLog","EventSystem","fdPHost","FDResPub","FontCache",
 "FrameServer","FrameServerMonitor","gpsvc","GraphicsPerfSvc","hidserv","HvHost",
 "IKEEXT","InstallService","iphlpsvc","KeyIso","KPSSVC","KtmRm","LanmanServer",
 "LanmanWorkstation","lfsvc","LicenseManager","lltdsvc","lmhosts","LSM","MapsBroker",
 "McpManagementService","MicrosoftEdgeElevationService","mpssvc","MSDTC","MSiSCSI",
 "msiserver","NcaSvc","NcbService","Netlogon","Netman","netprofm","NetSetupSvc",
 "NetTcpPortSharing","NgcCtnrSvc","NgcSvc","NlaSvc","nsi","PcaSvc","PerfHost","pla",
 "PlugPlay","PolicyAgent","Power","PrintNotify","ProfSvc","PushToInstall","QWAVE",
 "RasAuto","RasMan","RemoteAccess","RemoteRegistry","RmSvc","RpcEptMapper","RpcLocator",
 "RpcSs","RSoPProv","sacsvr","SamSs","SCardSvr","ScDeviceEnum","Schedule","SCPolicySvc",
 "seclogon","SecurityHealthService","SEMgrSvc","SENS","Sense","SensorDataService",
 "SensorService","SensrSvc","SessionEnv","SharedAccess","ShellHWDetection","shpamsvc",
 "smphost","SNMPTRAP","Spooler","sppsvc","SSDPSRV","ssh-agent","SstpSvc","StateRepository",
 "StiSvc","StorSvc","svsvc","swprv","SysMain","SystemEventsBroker","TabletInputService",
 "tapisrv","TermService","Themes","TieringEngineService","TimeBrokerSvc","TokenBroker",
 "TrkWks","TrustedInstaller","tzautoupdate","UALSVC","UevAgentService","UmRdpService",
 "upnphost","UserManager","UsoSvc","VaultSvc","vds","VSS","W32Time","WaaSMedicSvc",
 "WalletService","WarpJITSvc","WbioSrvc","Wcmsvc","WdiServiceHost","WdiSystemHost",
 "WdNisSvc","Wecsvc","WEPHOSTSVC","wercplsupport","WerSvc","WiaRpc","WinDefend",
 "WinHttpAutoProxySvc","Winmgmt","WinRM","wisvc","wlidsvc","wmiApSrv","WMPNetworkSvc",
 "WPDBusEnum","WpnService","WSearch","wuauserv","CaptureService_2bb53","cbdhsvc_2bb53",
 "CDPUserSvc_2bb53","ConsentUxUserSvc_2bb53","CredentialEnrollmentManagerUserSvc_2bb53",
 "DeviceAssociationBrokerSvc_2bb53","DevicePickerUserSvc_2bb53","DevicesFlowUserSvc_2bb53",
 "PimIndexMaintenanceSvc_2bb53","PrintWorkflowUserSvc_2bb53","UdkUserSvc_2bb53",
 "UnistoreSvc_2bb53","UserDataSvc_2bb53","WpnUserService_2bb53", #end base windows services
 "NTDS","DFSR","kdc","IsmServ","NtFrs","DsRoleSvc","KdsSvc","dfs","ADWS", #end AD services 
 "DNS", <#DNS server shortname#> "w3svc", <#Flask shortname#> "FTPSVC","MSFTPSVC", <#FTP shortnames#>
 "SMTPSVC","MSFTPSVC","POP3SVC","IMAPSVC", <#SMTP shortnames#> "W3SVC","HTTP","IISADMIN", <#HTTP shortnames#>
 "LanmanServer","LanmanWorkstation","Srv", <#SMB shortnames#> "WinRM","WSMan" <#WinRM shortnames#>
)
#Semi-Complete, contains all services for windows this comp

$mservs = Get-WmiObject Win32_Service | Select-Object Name, DisplayName, PathName, StartMode, StartName, State

# Export snapshot for later review
$mservs | Export-Csv -Path ".\services_snapshot.csv" -NoTypeInformation

# Determine extra services (present on host but NOT in your known-good list)
$extra = $mservs | Where-Object { $servnames -notcontains $_.Name }

# Preview — ALWAYS check before taking action
Write-Host "Found $($extra.Count) services not in known-good list. Preview:"
$extra | Select-Object Name,DisplayName,StartMode,StartName,PathName | Format-Table -AutoSize
#if malicious services found: Stop-Service -Name <malservname> -Force
#disable them: Set-Service -Name <malservname> -StartupType Disabled

# original states for restoring
$origState = $toActOn | Select-Object Name, @{n='StartMode';e={$_.StartMode}}, @{n='State';e={$_.State}}
$origState | Export-Csv -Path ".\orig_service_states.csv" -NoTypeInformation

# ===== restore snippet (run when you want to revert) =====
# $orig = Import-Csv .\orig_service_states.csv
# foreach ($r in $orig) {
#     try {
#         Write-Host "Restoring $($r.Name) startup type to $($r.StartMode)"
#         Set-Service -Name $r.Name -StartupType $r.StartMode
#         if ($r.State -eq 'Running') { Start-Service -Name $r.Name }
#     } catch {
#         Write-Warning "Failed to restore $($r.Name): $_"
#     }

# }

