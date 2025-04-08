# This script will ask how many days old and return a list of computers that have not logged in, this will query all domain controllers to compile the list


# Import the Active Directory module
Import-Module ActiveDirectory

# Prompt user for the number of days to filter stale computer accounts
$days = Read-Host -Prompt "Enter the number of days to find stale computer accounts"

# Calculate the cutoff date
$cutoffDate = (Get-Date).AddDays(-[int]$days)

# Get all domain controllers in the domain
$domainControllers = Get-ADDomainController -Filter *

# Create an array to store the results
$results = @()

# Get all computer accounts from Active Directory
$computers = Get-ADComputer -Filter * -Property Name

foreach ($computer in $computers) {
    $lastLogon = $null

    # Query each domain controller for the precise last logon time
    foreach ($dc in $domainControllers) {
        $logonInfo = Get-ADComputer -Identity $computer.DistinguishedName -Server $dc.HostName -Properties lastLogon
        if ($logonInfo.lastLogon) {
            $dcLastLogon = [DateTime]::FromFileTime($logonInfo.lastLogon)
            if (-not $lastLogon -or $dcLastLogon -gt $lastLogon) {
                $lastLogon = $dcLastLogon
            }
        }
    }

    # Check if the computer is stale
    if (-not $lastLogon -or $lastLogon -lt $cutoffDate) {
        $results += [PSCustomObject]@{
            ComputerName = $computer.Name
            LastLogonDate = $lastLogon
        }
    }
}

# Export the results to a CSV file
$results | Export-Csv -Path "StaleComputerAccounts.csv" -NoTypeInformation -Encoding UTF8

Write-Host "Stale computer accounts not logged into within the last $days days have been exported to 'StaleComputerAccounts.csv'"
