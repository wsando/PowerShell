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

    # Export XML and parse
    $reportXml = Get-GPOReport -Guid $gpo.Id -ReportType Xml
    [xml]$xml = $reportXml

    $settings = @()

    foreach ($scope in @("Computer", "User")) {
        $extensionsNode = $xml.GPO.$scope.ExtensionData
        if ($extensionsNode -and $extensionsNode.Extension) {
            $extensions = @()
            if ($extensionsNode.Extension -is [System.Xml.XmlElement]) {
                $extensions += $extensionsNode.Extension
            } else {
                $extensions += $extensionsNode.Extension
            }

            foreach ($ext in $extensions) {
                # 1. Admin Template Policies
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

                # 2. Windows Settings (Scripts, Folder Redirection, etc.)
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

                # 3. Catch-all for other extension settings (like IE/SoftwareInstall/etc.)
                foreach ($child in $ext.ChildNodes) {
                    if ($child.Name -notin @("Policy", "Properties")) {
                        $settings += [PSCustomObject]@{
                            GPOName       = $gpo.DisplayName
                            Scope         = $scope
                            SettingName   = $child.Name
                            SettingPath   = "$($ext.Name)\$($child.Name)"
                            Value         = $child.InnerText
                            RegistryKey   = "N/A"
                            RegistryValue = "N/A"
                        }
                    }
                }
            }
        }
    }

    # Always export CSV, even if empty
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

    # Summary metadata
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

    Write-Host "✅ Exported $($gpo.DisplayName): $($settings.Count) settings"
}

# Final summary export
$summaryList | Export-Csv -Path (Join-Path $summaryPath "GPO_Inventory_Summary.csv") -NoTypeInformation

Write-Host "`n🎉 GPO export complete! All files saved to: $basePath"
