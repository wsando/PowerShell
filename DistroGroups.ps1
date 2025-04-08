# This script will connect to Exchange Online and get all distribution groups and the usage in the last 30 days.
# Edit your connection login to your info
# Edit the output folder for the CSV to where you want it

# Connect to Exchange Online
Connect-ExchangeOnline -UserPrincipalName your_admin@yourdomain.com

# Get all Distribution Groups
$distributionLists = Get-DistributionGroup | Select-Object DisplayName, PrimarySmtpAddress

# Initialize an array to store results
$results = @()

# Loop through each distribution group and get email usage statistics
foreach ($group in $distributionLists) {
    # Get message trace statistics for the past 30 days
    $messageCount = (Get-MessageTrace -RecipientAddress $group.PrimarySmtpAddress -Start (Get-Date).AddDays(-30) -End (Get-Date)).Count

    # Create a custom object with the details
    $results += [PSCustomObject]@{
        Name                 = $group.DisplayName
        EmailAddress         = $group.PrimarySmtpAddress
        EmailsReceivedLast30d = $messageCount
    }
}

# Display results in a table
$results | Format-Table -AutoSize

# Optional: Export to CSV
$results | Export-Csv -Path "C:\Temp\DistributionListUsage_30Days.csv" -NoTypeInformation

# Disconnect from Exchange Online
Disconnect-ExchangeOnline -Confirm:$false
