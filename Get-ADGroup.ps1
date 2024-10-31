#This script will prompt to enter a Windows AD group and list all members of that group


# Ensure the Active Directory module is available
Import-Module ActiveDirectory

# Prompt for the group name
$groupName = Read-Host -Prompt "Enter the Active Directory group name"

# Get all members of the specified group
Get-ADGroupMember -Identity $groupName -Recursive | Select-Object Name, SamAccountName, ObjectClass
