# This script will scan all files in the given path and export a CSV file of duplicate files. It will include the name, path, date created, and date modified in the csv.

# Set paths
$Path = "C:\Your\Target\Directory"
$ExportCsv = "C:\Temp\DuplicateFiles_Marked.csv"

# Get all files recursively
$Files = Get-ChildItem -Path $Path -Recurse -File -ErrorAction SilentlyContinue

# Store file info with hashes
$FileHashList = @()

Write-Host "Calculating hashes..." -ForegroundColor Yellow

foreach ($File in $Files) {
    try {
        $Hash = Get-FileHash -Path $File.FullName -Algorithm SHA256
        $FileHashList += [PSCustomObject]@{
            FilePath      = $File.FullName
            FileSizeKB    = [Math]::Round($File.Length / 1KB, 2)
            LastModified  = $File.LastWriteTime
            DateCreated   = $File.CreationTime
            Hash          = $Hash.Hash
        }
    } catch {
        Write-Warning "Could not hash file: $($File.FullName)"
    }
}

# Group by hash to find duplicates
$DuplicateGroups = $FileHashList | Group-Object Hash | Where-Object { $_.Count -gt 1 }

# Flatten duplicate groups into a list with a "DuplicateStatus" marker
$MarkedDuplicates = @()
foreach ($Group in $DuplicateGroups) {
    $SortedGroup = $Group.Group | Sort-Object FilePath
    $Index = 0
    foreach ($File in $SortedGroup) {
        $Status = if ($Index -eq 0) { "Original" } else { "Duplicate" }
        $MarkedDuplicates += [PSCustomObject]@{
            FilePath       = $File.FilePath
            FileSizeKB     = $File.FileSizeKB
            LastModified   = $File.LastModified
            DateCreated    = $File.DateCreated
            Hash           = $File.Hash
            DuplicateStatus = $Status
        }
        $Index++
    }
}

# Export results
if ($MarkedDuplicates.Count -gt 0) {
    $MarkedDuplicates | Sort-Object Hash, DuplicateStatus, FilePath | Export-Csv -Path $ExportCsv -NoTypeInformation
    Write-Host "`nDuplicate file details with status exported to: $ExportCsv" -ForegroundColor Green
} else {
    Write-Host "`nNo duplicate files found." -ForegroundColor Green
}
