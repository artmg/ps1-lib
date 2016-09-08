

## Detect Monitors

Get-WmiObject -class Win32_DesktopMonitor

# If that does not enumerate them all then 

Get-WmiObject -class Win32_PnPEntity -filter 'service = "monitor"'




## Query Services from multiple computers into single CSV

# credit http://www.joshuastaylor.com/?p=19
$Servers = "MyServer001", " MyServer002"
ForEach-Object {Get-WmiObject -ComputerName $Servers Win32_Service} | # Query all services
# alternatives add filter such as     -filter "startname like '%administrator%'" 
Select SystemName,Name,StartName,StartMode,State | 
Export-CSV ServiceNowMidServerServices.csv # Export output to CSV



## Enumerate attributes from all group members

#Get the members of a group and return their user object with the mobile property
Get-ADGroupMember <GroupName> | Get-ADUser -Properties mobile



## SU - elevate the powershell console to a privileged user account
Start-Process powershell.exe -Credential (Get-Credential)
# afterwards set the title of the console
$host.ui.RawUI.WindowTitle = "USER:  " + [System.Environment]::UserDomainName +"\"+ [System.Environment]::UserName



## Test Credentials – does not require AD Snapin!

Function AskAndTest-UserCredential { 
  Write-Host "Please include the DOMAIN\ in username"
  # credit http://serverfault.com/a/276106 
  $cred = Get-Credential #Read credentials
  $username = $cred.username
  $password = $cred.GetNetworkCredential().password

  # credit http://serverfault.com/a/460486
  Add-Type -AssemblyName System.DirectoryServices.AccountManagement 
  $ct = [System.DirectoryServices.AccountManagement.ContextType]::Machine, $env:computername 
  $opt = [System.DirectoryServices.AccountManagement.ContextOptions]::SimpleBind 
  $pc = New-Object System.DirectoryServices.AccountManagement.PrincipalContext -ArgumentList $ct 
  $Result = $pc.ValidateCredentials($username, $password).ToString() 
  Remove-Variable password
  Write-Host "ValidCredentials = " $Result 
}


## alternative from http://serverfault.com/a/276106
## Get current domain using logged-on user's credentials
#$CurrentDomain = "LDAP://" + ([ADSI]"").distinguishedName
#$domain = New-Object System.DirectoryServices.DirectoryEntry($CurrentDomain,$UserName,$Password)
#If ($domain.name -eq $null) 
#{
# write-host "Authentication failed - please verify your username and password."
#}
#else
#{
# write-host "Successfully authenticated with domain $domain.name"
#}



# credit http://serverfault.com/a/460486
#usage: Test-UserCredential -username UserNameToTest -password (Read-Host)
Function Test-UserCredential { 
    Param($username, $password) 

    Add-Type -AssemblyName System.DirectoryServices.AccountManagement 
    $ct = [System.DirectoryServices.AccountManagement.ContextType]::Machine, $env:computername 
    $opt = [System.DirectoryServices.AccountManagement.ContextOptions]::SimpleBind 
    $pc = New-Object System.DirectoryServices.AccountManagement.PrincipalContext -ArgumentList $ct 
    $Result = $pc.ValidateCredentials($username, $password).ToString() 
    $Result 
}


Function Test-SecretCredential { 
    Param($username) 

  # credit - http://stackoverflow.com/a/15007402
$SecurePwd = Read-Host "Enter Password" -AsSecureString
  $Password = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecurePwd))
  $Result = Test-UserCredential -username UserNameToTest -password $Password
  Remove-Variable password
  $Result 
}




## create AD drive to forest root
New-PSDrive -Name "FR" -PSProvider ActiveDirectory -Server ((Get-ADForest).Name) -Root "//RootDSE/"
# use .SchemaMaster instead of name if you need to do anything specialised



## Check OU Permissions
# see https://gallery.technet.microsoft.com/Active-Directory-OU-1d09f989
# see also how to delegate using AD ACLs http://www.windowsecurity.com/articles-tutorials/authentication_and_encryption/securing-active-directory-powershell.html

