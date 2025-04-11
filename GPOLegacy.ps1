Import-Module GroupPolicy

# Output path
$outputPath = "C:\GPO_Migration\Summary\OrphanedUserSettings.csv"
$result = @()

$allGPOs = Get-GPO -All
foreach ($gpo in $allGPOs) {
    $reportXml = Get-GPOReport -Guid $gpo.Id -ReportType Xml
    [xml]$xml = $reportXml

    $extensionsNode = $xml.GPO.User.ExtensionData
    if ($extensionsNode -and $extensionsNode.Extension) {
        $extensions = @()
        if ($extensionsNode.Extension -is [System.Xml.XmlElement]) {
            $extensions += $extensionsNode.Extension
        } else {
            $extensions += $extensionsNode.Extension
        }

        foreach ($ext in $extensions) {
            $customSettingsFound = $false
            $legacyExtensions = @()

            foreach ($child in $ext.ChildNodes) {
                if ($child.Name -notin @("Policy", "Properties")) {
                    $customSettingsFound = $true
                    $legacyExtensions += $child.Name
                }
            }

            if ($customSettingsFound) {
                $result += [PSCustomObject]@{
                    GPOName           = $gpo.DisplayName
                    ExtensionName     = $ext.Name
                    SuspectedSettings = ($legacyExtensions -join ", ")
                    Scope             = "User"
                    Modified          = $gpo.ModificationTime
                }
            }
        }
    }
}

if ($result.Count -gt 0) {
    $result | Export-Csv -Path $outputPath -NoTypeInformation
    Write-Host "`n⚠️ Found $($result.Count) GPO(s) with potential orphaned user settings. Report saved to:"
    Write-Host $outputPath
} else {
    Write-Host "`n✅ No orphaned user settings detected."
}
