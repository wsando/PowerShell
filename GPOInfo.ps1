Import-Module GroupPolicy
Import-Module ActiveDirectory

# Output folders
$basePath = "C:\GPO_Migration"
$settingsPath = "$basePath\Settings"
$summaryPath = "$basePath\Summary"
New-Item -Path $settingsPath -ItemType Directory -Force | Out-Null
New-Item -Path $summaryPath -ItemType Directory -Force | Out-Null

$summaryList = @()

$allGPOs = Get-GPO -All
foreach ($gpo in $allGPOs) {
    $gpoNameSafe = ($gpo.DisplayName -replace '[\\/:*?"<>|]', '_')
    $csvPath = Join-Path $settingsPath "$gpoNameSafe.csv"

    # Export XML report
    $reportXml = Get-GPOReport -Guid $gpo.Id -ReportType Xml
    $xml = [xml]$reportXml

    $settings = @()

    foreach ($scope in @("Computer", "User")) {
        $extensions = $xml.GPO.$scope.ExtensionData.Extension
        foreach ($ext in $extensions) {
            foreach ($setting in $ext.Policy) {
                $settings += [PSCustomObject]@{
                    GPOName       = $gpo.DisplayName
                    Scope         = $scope
                    SettingName   = $setting.Name
                    SettingPath   = $setting.Path
                    Value         = $setting.State
                    RegistryKey   = $setting.RegistryKey
                    RegistryValue = $setting.RegistryValue
                }
            }
        }
    }

    $settings | Export-Csv -Path $csvPath -NoTypeInformation

    # Gather metadata: Linked OUs
    
    # Linked OUs from XML
$linkedOUs = $xml.GPO.LinksTo.SOMPath -join "; "

# Security Filtering
$acl = Get-GPPermission -Guid $gpo.Id -All | Where-Object { $_.Permission -match "GpoApply" } | Select-Object -ExpandProperty Trustee

# WMI Filter
$wmiFilter = if ($gpo.WmiFilter.Name) {
    "$($gpo.WmiFilter.Name): $($gpo.WmiFilter.Query)"
} else {
    "None"
}

    # Security Filtering
    $acl = Get-GPPermission -Guid $gpo.Id -All | Where-Object { $_.Permission -match "GpoApply" } | Select-Object -ExpandProperty Trustee

    # WMI Filter
    $wmiFilter = if ($gpo.WmiFilter.Name) {
        "$($gpo.WmiFilter.Name): $($gpo.WmiFilter.Query)"
    } else {
        "None"
    }

    $summaryList += [PSCustomObject]@{
        GPOName           = $gpo.DisplayName
        GUID              = $gpo.Id
        Created           = $gpo.CreationTime
        Modified          = $gpo.ModificationTime
        SettingsCount     = $settings.Count
        LinkedOUs         = ($linkedOUs -join "; ")
        SecurityFiltering = ($acl -join "; ")
        WMIFilter         = $wmiFilter
    }

    Write-Host "Exported settings for $($gpo.DisplayName)"
}

# Export summary
$summaryList | Export-Csv -Path (Join-Path $summaryPath "GPO_Inventory_Summary.csv") -NoTypeInformation

Write-Host "`n✅ GPO inventory and settings exported to $basePath"
