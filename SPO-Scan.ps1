# This script will crawl a given path for files with illegal charachters in the name or paths too long to migrate.

# Set the root path to scan
$RootPath = "C:\Your\Target\Directory"
$ExportCsv = "C:\Temp\InvalidFilesReport.csv"

# Define illegal characters for Windows file names
$IllegalChars = '[<>:"/\\|?*]'

# Create array for problematic files
$ProblemFiles = @()

Write-Host "Scanning files in: $RootPath" -ForegroundColor Yellow

# Get all files recursively
$Files = Get-ChildItem -Path $RootPath -Recurse -File -ErrorAction SilentlyContinue

foreach ($File in $Files) {
    $FullPath = $File.FullName
    $FileName = $File.Name
    $Issue = @()

    # Check for illegal characters in file name
    if ($FileName -match $IllegalChars) {
        $Issue += "IllegalCharacters"
    }

    # Check for path length > 260 characters
    if ($FullPath.Length -gt 260) {
        $Issue += "PathTooLong"
    }

    # If any issue detected, log it
    if ($Issue.Count -gt 0) {
        $ProblemFiles += [PSCustomObject]@{
            FilePath       = $FullPath
            FileName       = $FileName
            FileSizeKB     = [Math]::Round($File.Length / 1KB, 2)
            LastModified   = $File.LastWriteTime
            IssueDetected  = ($Issue -join ", ")
        }
    }
}

# Export to CSV
if ($ProblemFiles.Count -gt 0) {
    $ProblemFiles | Sort-Object IssueDetected, FilePath | Export-Csv -Path $ExportCsv -NoTypeInformation
    Write-Host "`nScan complete. Issues found: $($ProblemFiles.Count)" -ForegroundColor Green
    Write-Host "Results exported to: $ExportCsv" -ForegroundColor Cyan
} else {
    Write-Host "`nScan complete. No issues found." -ForegroundColor Green
}
