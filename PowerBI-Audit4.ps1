# This script audits all PowerBI workspaces, items, and admins for them and enumerates them as AD Display Names
# 1. Setup and Connection
# Ensure you have the Power BI and Active Directory modules installed
Import-Module MicrosoftPowerBIMgmt
Import-Module ActiveDirectory

Connect-PowerBIServiceAccount

# 2. Configuration
$outputPath = "C:\scripts\PowerBI_Full_Audit_Report.csv"
$adCache = @{} # Stores AD results to avoid redundant lookups

# Function to translate Power BI Identifier to AD DisplayName and Dept
function Get-ADUserDetails($identifier) {
    if ([string]::IsNullOrWhitespace($identifier)) { return "N/A", "N/A" }
    
    # Return from cache if already looked up
    if ($adCache.ContainsKey($identifier)) { 
        return $adCache[$identifier].Name, $adCache[$identifier].Dept 
    }

    try {
        # Search by UPN or Mail to find the Employee ID account
        $adUser = Get-ADUser -Filter "UserPrincipalName -eq '$identifier' -or mail -eq '$identifier'" -Properties Department, DisplayName
        
        if ($adUser) {
            # Use DisplayName (LAST, FIRST). Fallback to Name (Employee ID) if blank.
            $fullName = if (![string]::IsNullOrWhitespace($adUser.DisplayName)) { $adUser.DisplayName } else { $adUser.Name }
            $dept = $adUser.Department
            
            $adCache[$identifier] = @{ Name = $fullName; Dept = $dept }
            return $fullName, $dept
        }
    } catch {
        # Fail silently for Service Principals or External Guests
    }

    # Fallback if not found in AD
    return $identifier, "External/Guest"
}

# 3. Fetch Power BI Data via REST API
Write-Host "Calling Power BI REST API (Fetching all Workspaces + Contents)..." -ForegroundColor Cyan
$url = "admin/groups?`$expand=users,dashboards,reports&`$top=5000"
$allWorkspaces = @()

do {
    $response = Invoke-PowerBIRestMethod -Url $url -Method Get | ConvertFrom-Json
    $allWorkspaces += $response.value
    $url = $response.'@odata.nextLink'
} while ($url -ne $null)

# 4. Process and Map Data
$report = New-Object System.Collections.Generic.List[PSCustomObject]
Write-Host "Processing $($allWorkspaces.Count) workspaces and mapping to AD..." -ForegroundColor Yellow

foreach ($ws in $allWorkspaces) {
    # Identify Workspace Admins
    $adminUPNs = ($ws.users | Where-Object { $_.groupUserAccessRight -eq "Admin" }).identifier
    
    $adminNames = @()
    $adminDepts = @()

    foreach ($upn in $adminUPNs) {
        $name, $dept = Get-ADUserDetails $upn
        $adminNames += $name
        if ($dept) { $adminDepts += $dept }
    }

    # Helper logic to process Dashboards and Reports
    $wsContents = @()
    if ($ws.dashboards) { $wsContents += $ws.dashboards | Select-Object *, @{n='ItemType';e={'Dashboard'}} }
    if ($ws.reports)    { $wsContents += $ws.reports | Select-Object *, @{n='ItemType';e={'Report'}} }

    foreach ($item in $wsContents) {
        # Clean up Names and Departments (handle multiples if they exist)
        $finalNames = ($adminNames | Where-Object { $_ }) -join "; "
        $finalDepts = ($adminDepts | Where-Object { $_ } | Select-Object -Unique) -join "; "

        $report.Add([PSCustomObject]@{
            ContentType      = $item.ItemType
            ContentName      = if ($item.ItemType -eq "Report") { $item.name } else { $item.displayName }
            WorkspaceName    = $ws.name
            WorkspaceType    = $ws.type
            OwnerNames       = $finalNames
            OwnerDepartments = $finalDepts
            ContentId        = $item.id
            WorkspaceId      = $ws.id
        })
    }
}

# 5. Export to CSV
if ($report.Count -gt 0) {
    # Ensure directory exists
    $dir = Split-Path $outputPath
    if (!(Test-Path $dir)) { New-Item -ItemType Directory -Path $dir }

    $report | Export-Csv $outputPath -NoTypeInformation -Encoding UTF8
    Write-Host "Success! Report saved to: $outputPath" -ForegroundColor Green
} else {
    Write-Warning "No dashboards or reports found."
}