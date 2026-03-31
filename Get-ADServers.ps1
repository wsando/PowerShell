# This script will list out all SERVER computer objects in the domain, including the name, description, creation date, who created the object, and OS.
# Requires Active Directory module
# Import-Module ActiveDirectory  # Uncomment if not auto-loaded

function Get-ServerAccountDetails {
    param (
        [string]$SearchBase = "",        # Optional: limit to specific OU
        [string]$Server = ""             # Optional: specify a DC
    )

    $params = @{
        LDAPFilter = "(operatingSystem=*Server*)"
        Properties = @(
            "Name",
            "Description",
            "whenCreated",
            "nTSecurityDescriptor",
            "DistinguishedName",
            "OperatingSystem",
            "LastLogonDate"
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
            Name            = $computer.Name
            OperatingSystem = $computer.OperatingSystem
            Description     = $computer.Description
            CreatedDate     = $computer.whenCreated
            CreatedBy       = $creator
            OU              = $ou
            LastLogon       = $computer.LastLogonDate
        })
    }

    return $results
}

# --- Run and display ---
$servers = Get-ServerAccountDetails

if ($servers -and $servers.Count -gt 0) {
    $servers | Format-Table -AutoSize
    # Export to CSV
    $servers | Export-Csv -Path "c:\scripts\ServerAccounts.csv" -NoTypeInformation
    Write-Host "Exported $($servers.Count) records to ServerAccounts.csv" -ForegroundColor Green
} else {
    Write-Host "No server accounts found or an error occurred." -ForegroundColor Yellow
}