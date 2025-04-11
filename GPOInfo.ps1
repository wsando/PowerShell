Import-Module GroupPolicy
Import-Module ActiveDirectory

# Output directories
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

    # Get XML report and parse
    $reportXml = Get-GPOReport -Guid $gpo.Id -ReportType Xml
    [xml]$xml = $reportXml

    $settings = @()

    foreach ($scope in @("Computer", "User")) {
        $extensionsNode = $xml.GPO.$scope.ExtensionData
        if ($extensionsNode -and $extensionsNode.Extension) {
            $extensions = $extensionsNode.Extension
            foreach ($ext in $extensions) {
                # Admin Template Policies
                if ($ext.Policy) {
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

                # Windows Settings (e.g., Scripts, Folder Redirection, etc.)
                if ($ext.Properties) {
                    foreach ($prop in $ext.Properties.ChildNodes) {
                        $settings += [PSCustomObject]@{
                            GPOName       = $gpo.DisplayName
                            Scope         = $scope
                            SettingName   = $prop.Name
                            SettingPath   = "$($ext.Name)\$($prop.Name)"
                            Value         = $prop.InnerText
                            RegistryKey   = "N/A"
                            RegistryValue = "N/A"
                        }
                    }
                }
            }
        }
    }

    # Always export, even if empty
    $settings | Export-Csv -Path $csvPath -NoTypeInformation

    # Linked OUs
    $linkedOUs = $xml.GPO.LinksTo.SOMPath -join "; "

    # Security Filtering
    $acl = Get-GPPermission -Guid $gpo.Id -All |
        Where-Object { $_.Permission -match "GpoApply" } |
        Select-Object -ExpandProperty Trustee

    # WMI Filter
    $wmiFilter = if ($gpo.WmiFilter.Name) {
        "$($gpo.WmiFilter.Name): $($gpo.WmiFilter.Query)"
    } else {
        "None"
    }

    # Summary
    $summaryList += [PSCustomObject]@{
        GPOName           = $gpo.DisplayName
        GUID              = $gpo.Id
        Created           = $gpo.CreationTime
        Modified          = $gpo.ModificationTime
        SettingsCount     = $settings.Count
        HasSettings       = if ($settings.Count -gt 0) { "Yes" } else { "No" }
        LinkedOUs         = $linkedOUs
        SecurityFiltering = ($acl -join "; ")
        WMIFilter         = $wmiFilter
    }

    Write-Host "Exported $($gpo.DisplayName): $($settings.Count) settings"
}

# Export summary
$summaryList | Export-Csv -Path (Join-Path $summaryPath "GPO_Inventory_Summary.csv") -NoTypeInformation

Write-Host "ALL GPO inventory complete. Files saved to: $basePath"
