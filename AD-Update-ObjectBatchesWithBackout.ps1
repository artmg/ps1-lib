##
## AD-Update-ObjectBatchesWithBackout.ps1
##
## Set AD attributes from CSV...
## – ONLY when new value is specified and 
## - create backout file of previous values
##
## This is designed to work with Contacts as well as users, 
## so it uses ADObject rather than ADUser.
## AD Objects are identified here by distinguishedName
## but any valid -Identity may be used instead e.g. GUID
##
## Object Attributes are set using their LDAPDisplayName equivalents
## rather than the AD Object Property or actual Attribute names
## see http://social.technet.microsoft.com/wiki/contents/articles/12037.active-directory-get-aduser-default-and-extended-properties.aspx
##
## For simplicity the CSV column names are the LDAPDisplayName 
## to allow for wider reuse (and future creation of an automated loop)
## 
## As we assume directory changes require elevation this 
## asks for the Credential if none has been supplied yet
## If you need to change credentials for multiple executions use
##    Clear-Variable Credential
##
## 160906.AMG backout file timestamped in case run multiple times
## 160905.AMG created with backout and manual list of attributes
##

Import-module ActiveDirectory

# set this to True when you want to run it for real
$ReallyApplyChanges = $True

$BatchID="First"
$Domain="Dom1"
if (!$Credential) { $Credential = Get-Credential }

$OldValues = @();
Import-CSV ("AD-Update-ObjectBatch-" + $BatchID + ".csv") | 
Foreach-Object {
    # define object to hold values to roll-back
    $OldValue = "" | Select-Object distinguishedName, ipPhone, pager, telephoneNumber

    # get the user
    $Account = Get-ADObject -Server $Domain -Credential $Credential -Identity $_.distinguishedName –Properties * 
    # check it matches before continuing
    if ($Account.distinguishedName -eq $Account.distinguishedName) {
        $OldValue.distinguishedName = $Account.distinguishedName 

        # for each new value defined, store the old and replace with the new
        if (!$($_.ipPhone -eq "")) {
            $OldValue.ipPhone = $Account.ipPhone ; 
            if ($ReallyApplyChanges) { $Account | Set-ADObject -Server $Domain -Credential $Credential -Replace @{ipPhone=$_.ipPhone} ; }
            }

        if (!$($_.pager -eq "")) {
            $OldValue.pager = $Account.pager ; 
            if ($ReallyApplyChanges) { $Account | Set-ADObject -Server $Domain -Credential $Credential -Replace @{pager=$_.pager} ; }
            }

        if (!$($_.telephoneNumber -eq "")) {
            $OldValue.telephoneNumber = $Account.telephoneNumber ; 
            if ($ReallyApplyChanges) { $Account | Set-ADObject -Server $Domain -Credential $Credential -Replace @{telephoneNumber=$_.telephoneNumber} ; }
            }

        # add to array ready for export
        $OldValues += $OldValue
    }
}
$OldValues | Export-CSV ("AD-Update-ObjectBatch-" + $BatchID + ".BackoutValues." + $(get-date -f HH_mm_ss) + ".csv")  -NoTypeInformation


## end of code
