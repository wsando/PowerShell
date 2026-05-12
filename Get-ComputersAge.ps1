# This script will list out all computer objects in the domain, include the name, Description, creation date, and who created the object.
# Requires Active Directory module
# Import-Module ActiveDirectory  # Uncomment if not auto-loaded

function Get-ComputerAccountDetails {
    param (
        [string]$SearchBase = "",        # Optional: limit to specific OU
        [string]$Server = ""             # Optional: specify a DC
    )

    $params = @{
        Filter     = "*"
        Properties = @(
            "Name",
            "Description",
            "whenCreated",
            "nTSecurityDescriptor",
            "DistinguishedName"
        )
    }

    if ($SearchBase) { $params["SearchBase"] = $SearchBase }
    if ($Server)     { $params["Server"]     = $Server }

    $computers = Get-ADComputer @params

    # Use an explicit list to collect results reliably in PowerShell 7
    $results = [System.Collections.Generic.List[PSCustomObject]]::new()

    foreach ($computer in $computers) {
        # Extract the creator from the security descriptor owner
        $creator = try {
            $computer.nTSecurityDescriptor.Owner
        } catch {
            "N/A"
        }

        # Parse the OU from the DistinguishedName by stripping the first CN component
        $ou = ($computer.DistinguishedName -split ",", 2)[1]

        $results.Add([PSCustomObject]@{
            Name        = $computer.Name
            Description = $computer.Description
            CreatedDate = $computer.whenCreated
            CreatedBy   = $creator
            OU          = $ou
        })
    }

    return $results
}

# --- Run and display ---
$computers = Get-ComputerAccountDetails

if ($computers -and $computers.Count -gt 0) {
    $computers | Format-Table -AutoSize

    # Export to CSV
    $computers | Export-Csv -Path ".\ComputerAccounts.csv" -NoTypeInformation
    Write-Host "Exported $($computers.Count) records to ComputerAccounts.csv" -ForegroundColor Green
} else {
    Write-Host "No computer accounts found or an error occurred." -ForegroundColor Yellow
}