# This script will list out all computer objects in the domain, include the name, descrrition, creation date, and who created the object.


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

    $results = foreach ($computer in $computers) {
        # Extract the creator from the security descriptor owner
        $creator = try {
            $computer.nTSecurityDescriptor.Owner
        } catch {
            "N/A"
        }

        # Parse the OU from the DistinguishedName by stripping the first CN component
        $ou = ($computer.DistinguishedName -split ",", 2)[1]

        [PSCustomObject]@{
            Name        = $computer.Name
            Description = $computer.Description
            CreatedDate = $computer.whenCreated
            CreatedBy   = $creator
            OU          = $ou
        }
    }

    return $results
}

# --- Run and display ---
$computers = Get-ComputerAccountDetails

$computers | Format-Table -AutoSize

# Optional: Export to CSV
# $computers | Export-Csv -Path ".\ComputerAccounts.csv" -NoTypeInformation
```

**What changed:**
- Added `DistinguishedName` to the properties list — this is always returned by AD and contains the full LDAP path of the object
- The OU is parsed by splitting the `DistinguishedName` on the first comma and taking everything after it, which strips the `CN=ComputerName` portion and leaves the full OU path

**Example output for the OU field:**
```
# Full DN:  CN=DESKTOP-01,OU=Workstations,OU=Computers,DC=contoso,DC=com
# OU field: OU=Workstations,OU=Computers,DC=contoso,DC=com