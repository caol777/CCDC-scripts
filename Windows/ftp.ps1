Install-WindowsFeature Web-FTP-Server, Web-FTP-Service, Web-FTP-Ext
Install-WindowsFeature Web-Server, Web-Security

#change ftp.example.local? gpt said nothing about this
New-SelfSignedCertificate -DnsName "ftp.example.local" -CertStoreLocation "cert:\LocalMachine\My"

#change default site to comp ftp site name
Set-WebConfigurationProperty -filter "system.ftpServer/security/ssl" -name "controlChannelPolicy" -value "SslRequire" -PSPath IIS:\ -location "Default FTP Site"
Set-WebConfigurationProperty -filter "system.ftpServer/security/ssl" -name "dataChannelPolicy" -value "SslRequire" -PSPath IIS:\ -location "Default FTP Site"


New-LocalUser -Name "ftp_user" -Password (Read-Host -AsSecureString "Enter Password") -PasswordNeverExpires $true

New-Item -ItemType Directory -Path "C:\FTP\ftp_user"

icacls "C:\FTP\ftp_user" /inheritance:r
icacls "C:\FTP\ftp_user" /grant ftp_user:(OI)(CI)(RX)


icacls "C:\FTP\ftp_user" /remove:g Everyone

Add-WebConfiguration -Filter "system.ftpServer/security/authorization" -PSPath IIS:\ -Location "Default FTP Site" -Value @{accessType="Allow"; users="ftp_user"; permissions="Read,Write"}


Set-WebConfigurationProperty -filter "system.ftpServer/security/authentication/anonymousAuthentication" -name enabled -value false -PSPath IIS:\ -location "Default FTP Site"
Set-WebConfigurationProperty -filter "system.ftpServer/security/authentication/basicAuthentication" -name enabled -value true -PSPath IIS:\ -location "Default FTP Site"


Set-WebConfigurationProperty -Filter "system.ftpServer/firewallSupport" -Name "dataChannelPortRange" -Value "50000-50100" -PSPath IIS:\ -Location "Default FTP Site"


New-NetFirewallRule -DisplayName "FTP Passive Ports" -Direction Inbound -Protocol TCP -LocalPort 50000-50100 -Action Allow
New-NetFirewallRule -DisplayName "FTP Command Port" -Direction Inbound -Protocol TCP -LocalPort 21 -Action Allow

#change to comp IP's
New-NetFirewallRule -DisplayName "FTP Allow Trusted IPs" -Direction Inbound -Protocol TCP -LocalPort 21,50000-50100 -RemoteAddress 10.0.0.5,10.0.0.6 -Action Allow

New-NetFirewallRule -DisplayName "FTP Block All" -Direction Inbound -Protocol TCP -LocalPort 21,50000-50100 -Action Block


Set-WebConfigurationProperty -filter "system.applicationHost/sites/siteDefaults/ftpServer/logFile" -name "directory" -value "C:\inetpub\logs\LogFiles"
Set-WebConfigurationProperty -filter "system.applicationHost/sites/siteDefaults/ftpServer/logFile" -name "logExtFileFlags" -value "Date, Time, ClientIP, UserName, Method, UriStem, BytesSent, BytesReceived, Win32Status, ProtocolStatus"


New-Item "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Server" -Force
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Server" -Name "Enabled" -Value 0


New-Item "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Server" -Force
Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Server" "Enabled" 0

New-Item "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Server" -Force
Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Server" "Enabled" 0


Set-WebConfigurationProperty -filter "system.ftpServer/userIsolation" -name "mode" -value "Isolated" -PSPath IIS:\ -location "Default FTP Site"
New-Item -ItemType Directory -Path "C:\FTP\LocalUser\ftp_user"


Set-WebConfigurationProperty -filter "system.ftpServer/security/ipSecurity" -name allowUnlisted -value false -PSPath IIS:\ -location "Default FTP Site"

#change to comp IP's
Add-WebConfiguration "system.ftpServer/security/ipSecurity/add" -value @{ipAddress="10.0.0.5"; allowed="true"} -PSPath IIS:\ -Location "Default FTP Site"
Add-WebConfiguration "system.ftpServer/security/ipSecurity/add" -value @{ipAddress="10.0.0.6"; allowed="true"} -PSPath IIS:\ -Location "Default FTP Site"


auditpol /set /subcategory:"Filtering Platform Packet Drop" /success:enable /failure:enable
auditpol /set /subcategory:"Filtering Platform Connection" /success:enable /failure:enable


Set-WebConfigurationProperty -filter "system.ftpServer/directoryBrowse" -name "showFlags" -value "None" -PSPath IIS:\ -location "Default FTP Site"
Set-WebConfigurationProperty -filter "system.ftpServer/security/authentication/anonymousAuthentication" -name "enabled" -value false -PSPath IIS:\ -location "Default FTP Site"
icacls "C:\FTP" /deny Users:(W)


