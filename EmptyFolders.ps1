# This script will crawl a given path and list all empty folders

# Set the target path
$Path = "C:\Your\Target\Directory"

# Get all directories recursively and check if they are empty
$EmptyFolders = Get-ChildItem -Path $Path -Recurse -Directory |
    Where-Object {
        @(Get-ChildItem -Path $_.FullName -Force -ErrorAction SilentlyContinue).Count -eq 0
    }

# Output empty folders
$EmptyFolders | Select-Object FullName

# Optional: Export to CSV
$ExportCsv = "C:\Temp\EmptyFolders.csv"
$EmptyFolders | Select-Object FullName | Export-Csv -Path $ExportCsv -NoTypeInformation

Write-Host "`nEmpty folder list exported to: $ExportCsv" -ForegroundColor Green
