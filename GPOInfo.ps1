# This script gathers basic information on the Group Policy Objects (GPO) in the Active Directory 

Import-Module GroupPolicy

# Output path
$exportPath = "C:\GPO_Inventory.csv"

# Gather GPO info
$gpos = Get-GPO -All | ForEach-Object {
    $report = Get-GPOReport -Guid $_.Id -ReportType Xml
    $xml = [xml]$report
    $settingsCount = $xml.GPO.Computer.ExtensionData.Extension | Measure-Object -Property Name | Select-Object -ExpandProperty Count
    [PSCustomObject]@{
        DisplayName       = $_.DisplayName
        GUID              = $_.Id
        Created           = $_.CreationTime
        Modified          = $_.ModificationTime
        Status            = $_.GpoStatus
        SettingsCount     = $settingsCount
    }
}

$gpos | Export-Csv -Path $exportPath -NoTypeInformation
Write-Output "Export complete: $exportPath"
