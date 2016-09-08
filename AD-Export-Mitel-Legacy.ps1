##
## PowerShell CSV export of Mitel Directory information for users NOT YET MIGRATED
## from AD domains, both users and Contacts
##
##
##
## This currently filters out:
##   * disabled accounts
##   * EmployeeType=Process  (e.g. admin accounts, service accounts, etc)
##   * any objects that have NO phone number under IP, DDI, Mobile, Pager or Fax
##
##
##  160908.AMG  removed unwanted fields and filter to include ONLY when there is an Extension number
##  160908.AMG  match output format to sample CSV and filter on HomeElement
##  160902.AMG  created from contact export adding filters
##

Import-Module ActiveDirectory

$Domains = "Dom1", "Dom2"
$ObjectClasses = "(|(objectClass=Contact)(&(objectClass=User)(objectCategory=Person)))"
$IsEnabled = "(!(useraccountcontrol:1.2.840.113556.1.4.803:=2))"
$HasExtension = "(IPPhone=*)"
$HasNoHomeElement = "(!(ExtensionAttribute10=*))"
$LDAPFilter = "(& " + $ObjectClasses + " (DisplayName=*)  (!(EmployeeType=Process)) " + 
    $HasNoHomeElement + $HasExtension + $IsEnabled + " )"

$ExportOptions = @{Append = $false} # First time do not append
ForEach ($Domain in $Domains) 
{
  Get-ADObject –Server $Domain -LDAPFilter $LDAPFilter –Properties * | 
    Select @{ Name = 'Name_';                            Expression = { $_.sn + ’,’ + $_.givenName }}, 
      @{ Name = 'Number';                                Expression = { $_.IPPhone }}, 
      @{ Name = 'Prime Name';                            Expression = { 'No' }}, 
      @{ Name = 'Privacy';                               Expression = { 'No' }}, 
      Department, 
      @{ Name = 'Location';                              Expression = { $_.physicalDeliveryOfficeName }},
      @{ Name = 'PNI';                                   Expression = { '' }},
      @{ Name = 'GUID';                                  Expression = { $_.ObjectGUID }} | 

    Export-Csv –Path  ([environment]::getfolderpath("MyDocuments")+"\Mitel-Directory-unmigrated-AD-Export." + (Get-Date -Format "yy-MM-dd") + ".csv") @ExportOptions –NoTypeInformation 
  $ExportOptions = @{Append = $true} # First time do not append
}


# end of code
#


