# This script will dump all Group Policy Objects (GPO) and give a list of all settings that overlap between policies.

Import-Module GroupPolicy

# Output directories
$basePath = "C:\GPO_Migration"
$settingsPath = "$basePath\Settings"
$summaryPath = "$basePath\Summary"

New-Item -Path $settingsPath -ItemType Directory -Force | Out-Null
New-Item -Path $summaryPath -ItemType Directory -Force | Out-Null

# Hashtable to track settings across GPOs
$settingMap = @{}

# Process each GPO
$allGPOs = Get-GPO -All
foreach ($gpo in $allGPOs) {
    $reportXml = Get-GPOReport -Guid $gpo.Id -ReportType Xml
    $xml = [xml]$reportXml
    $gpoNameSafe = ($gpo.DisplayName -replace '[\\/:*?"<>|]', '_')
    $csvPath = Join-Path $settingsPath "$gpoNameSafe.csv"

    $settings = @()

    # Handle Computer & User Extensions
    foreach ($scope in @("Computer", "User")) {
        $extensions = $xml.GPO.$scope.ExtensionData.Extension
        foreach ($ext in $extensions) {
            foreach ($setting in $ext.Policy) {
                $path = $setting.Path
                $name = $setting.Name
                $value = $setting.State
                $regKey = $setting.RegistryKey
                $regValue = $setting.RegistryValue

                $key = "$path\$name"

                $settings += [PSCustomObject]@{
                    GPOName       = $gpo.DisplayName
                    Scope         = $scope
                    SettingName   = $name
                    SettingPath   = $path
                    Value         = $value
                    RegistryKey   = $regKey
                    RegistryValue = $regValue
                }

                # Track for overlap summary
                if (-not $settingMap.ContainsKey($key)) {
                    $settingMap[$key] = @()
                }
                $settingMap[$key] += $gpo.DisplayName
            }
        }
    }

    $settings | Export-Csv -Path $csvPath -NoTypeInformation
    Write-Host "Exported settings for $($gpo.DisplayName)"
}

# Create overlap summary
$overlap = foreach ($entry in $settingMap.GetEnumerator()) {
    if ($entry.Value.Count -gt 1) {
        [PSCustomObject]@{
            SettingPath = $entry.Key
            GPOs        = ($entry.Value -join '; ')
            Count       = $entry.Value.Count
        }
    }
}

$overlap | Export-Csv -Path (Join-Path $summaryPath "GPO_Overlapping_Settings.csv") -NoTypeInformation

Write-Host "`n✅ Export complete:"
Write-Host "- Settings per GPO saved to: $settingsPath"
Write-Host "- Overlapping settings report: $summaryPath\GPO_Overlapping_Settings.csv"
