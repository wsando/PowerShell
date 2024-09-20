<#
	.SYNOPSIS
		Disable ActiveSync for all users NOT in AD group and enable it for all users in that same group
	.DESCRIPTION
    	Disable ActiveSync for all users NOT in AD group and enable it for all users in that same group
	.PARAMETER
	.INPUTS
	.OUTPUTS
	.EXAMPLE
	.NOTES
		NAME:  Set-ActiveSyncEnabled.ps1
		AUTHOR: Charles Downing
		LASTEDIT: 06/20/2012
		KEYWORDS:
	.LINK
#>

# Add Exchange Admin module
If ((Get-PSSnapin | where {$_.Name -match "Exchange.Management"}) -eq $null)
{
	Add-PSSnapin Microsoft.Exchange.Management.PowerShell.Admin
}

# Assign ALL USERS to a dynamic array
$allUsers = get-Mailbox -ResultSize:unlimited

# Assign all members of the ALLOWED GROUP to a dynamic array
$groupUsers = Get-DistributionGroupMember -Identity 'Exchange ActiveSync Allowed'

# Loop through array of all users
foreach ($member in $allUsers) 
{
	$str = ""
	
	#get CAS attributes for current user
	$mailbox = Get-CasMailbox -resultsize unlimited -identity $member.Name
	
	#determine if current user is member of allowed group
	if(($groupUsers | where-object{$_.Name -eq $member.Name}))
	{
		#if user already has ActiveSync enabled, do nothing
		if ($mailbox.ActiveSyncEnabled -eq "true")
		{
			$str += "Current - enabled - " 
		}
		#if user does not have ActiveSync enabled, enable it
		else
		{
			$member | Set-CASMailbox –ActiveSyncEnabled $true
			$str += "Enabled - "
		}
	}
	#if user is not member of allowed group, disable ActiveSync
	else
	{
		if ($mailbox.ActiveSyncEnabled -eq "true")
		{
			$member | Set-CASMailbox –ActiveSyncEnabled $false
			$str = "Disabled - "
		}
		else
		{
			$str += "Current - disabled - "
		}
	}

	$str += $mailbox.Name + "`n"
	echo $str
}