
##
## Get all Contact and User objects from both domains
##
##
## The main functional difference between Contacts and Users 
## is that Users are also a Security Principal and therefore 
## can log on and be assigned security permissions.
## 
## Both object classes User 
## https://msdn.microsoft.com/en-us/library/ms683980(v=vs.85).aspx#win_2008_r2 
## and Contact 
## https://msdn.microsoft.com/en-us/library/ms680995(v=vs.85).aspx#win_2008_r2 
## inherit directly from Organizational-Person 
## https://msdn.microsoft.com/en-us/library/ms683883(v=vs.85).aspx#win_2008_r2 
## and all three are in the Object Category "person"
## 
## To get only Contacts, use
## Get-ADObject -LDAPFilter “objectClass=Contact” –Properties * | Export-Csv "Contacts All Properties.csv"
##
## Note that Get-ADUser extended Properties are named using the LDAPDisplayName of the Attribute 
## whereas Get-ADObject Properties is based on the actual Attribute name
## For a translation table between these see the MS article
## "Active Directory: Get-ADUser Default and Extended Properties"
## http://social.technet.microsoft.com/wiki/contents/articles/12037.active-directory-get-aduser-default-and-extended-properties.aspx
##
##  160907.AMG  additional attributes
##  160831.AMG  add Domain to output
##

$Domains = "Dom1", "Dom2"
# $Domains = [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest() | select domains

$ExportOptions = @{Append = $false} # First time do not append
ForEach ($Domain in $Domains) 
{
  $DomainNBN = (Get-ADDomain $Domain).NetBIOSName

# filter in LDAP on either Contact OR User (but excluding Computers)
# alternatively you could simply use "(objectCategory=person)" to include both, but this may include other classes too
  Get-ADObject –Server $Domain -LDAPFilter "(|(objectClass=Contact)(&(objectClass=User)(objectCategory=Person)))" –Properties * | 
    Select Name, ObjectClass, CN, DisplayName, PersonalTitle, givenName, 
      Description, Title, Department, Division, EmployeeType, EmployeeNumber, Company, 
      streetaddress, PostalCode, IPPhone, ExtensionAttribute1, Manager, msExchAssistantName, Pager, 
      FacsimileTelephoneNumber, 

      # return the following Attributes with the friendlier LDAPDisplayName as the Property name, just like get-ADUser does 
      @{ Name = 'Surname';           Expression = { $_.sn }}, 
      @{ Name = 'Office';            Expression = { $_.physicalDeliveryOfficeName }},
      @{ Name = 'City';              Expression = { $_.l }},
      @{ Name = 'OfficePhone';       Expression = { $_.TelephoneNumber }}, 
      @{ Name = 'MobilePhone';       Expression = { $_. Mobile }}, 
      @{ Name = 'departmentNumber';  Expression = { $_.departmentNumber }}, 

      # type conversion to make the output friendlier (like Get-ADUser does) 
      # date format alternative ToString("yyyy-MM-dd")  
      @{ Name = 'Enabled';           Expression = { ($_.userAccountControl –band 0x00000002) –eq 0 }}, 
      @{ Name = 'lastLogonDate';     Expression = { [DateTime]::FromFileTime($_.lastLogonTimeStamp). ToShortDateString() }}, 
      @{ Name = 'ManagerName';       Expression = { (Get-ADUser $_.Manager).Name }}, 

      # mail-related info
      mail, mailNickname, targetAddress, 

      # the following attributes are multiple valued, so we convert them to a simple semicolon delimited string 
      @{ Name = 'showInAddressBook'; Expression = { $_.showInAddressBook -join ';'; }; }, 
      @{ Name = 'proxyAddresses';    Expression = { $_.proxyAddresses    -join ';'; }; }, 
      @{ Name = 'altRecipientBL';    Expression = { $_.altRecipientBL    -join ';'; }; },
      @{ Name = 'Proxy-Addresses';   Expression = { $_.proxyAddresses    -join ';'; }; },
      @{ Name = 'ExchMAPI-Recipient';Expression = { $_.mAPIRecipient     -join ';'; }; },

      @{ Name = 'OtherFax';          Expression = { $_.otherFacsimileTelephoneNumber }}, 
      @{ Name = 'Comment';           Expression = { $_.info }}, 

      # keep these techie attributes until the end 
      Modified, CanonicalName, DistinguishedName, ObjectGUID, 
      @{ Name = 'Domain';            Expression = { $DomainNBN }} | 

    Export-Csv –Path  ([environment]::getfolderpath("MyDocuments")+"\ContactDetails.csv") @ExportOptions –NoTypeInformation 
  $ExportOptions = @{Append = $true} # First time do not append
}

# end of code


