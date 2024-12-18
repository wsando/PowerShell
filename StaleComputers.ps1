# This script will ask how many days old and return a list of computers that have not logged in since then

# Import the Active Directory module
Import-Module ActiveDirectory

# Prompt user for the number of days to filter stale computer accounts
$days = Read-Host -Prompt "Enter the number of days to find stale computer accounts"

# Calculate the cutoff date
$cutoffDate = (Get-Date).AddDays(-[int]$days)

# Get all computer accounts from Active Directory
$computers = Get-ADComputer -Filter * -Property Name, LastLogonDate

# Create an array to store the results
$results = @()

foreach ($computer in $computers) {
    if ($computer.LastLogonDate -lt $cutoffDate -or !$computer.LastLogonDate) {
        $results += [PSCustomObject]@{
            ComputerName = $computer.Name
            LastLogonDate = $computer.LastLogonDate
        }
    }
}

# Export the results to a CSV file
$results | Export-Csv -Path "StaleComputerAccounts.csv" -NoTypeInformation -Encoding UTF8

Write-Host "Stale computer accounts not logged into within the last $days days have been exported to 'StaleComputerAccounts.csv'"
