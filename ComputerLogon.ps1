# This script will querry AD servers, pull all the computer names, and then get the last login time for the computer

# Import the Active Directory module
Import-Module ActiveDirectory

# Get all computer accounts from Active Directory
$computers = Get-ADComputer -Filter * -Property Name, LastLogonDate

# Create an array to store the results
$results = @()

foreach ($computer in $computers) {
    $results += [PSCustomObject]@{
        ComputerName = $computer.Name
        LastLogonDate = $computer.LastLogonDate
    }
}

# Export the results to a CSV file
$results | Export-Csv -Path "ComputerLastLogon.csv" -NoTypeInformation -Encoding UTF8

Write-Host "The last logon data for all computer accounts has been exported to 'ComputerLastLogon.csv'"
