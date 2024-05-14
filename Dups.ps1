# this script will crawl the specified path and list all duplicate files and export the results to csv

# Prompt the user to enter a directory path
$directoryPath = Read-Host "Enter the directory path"

# Check if the directory exists
if (-Not (Test-Path -Path $directoryPath)) {
    Write-Host "The specified directory does not exist."
    exit
}

# Get all files in the directory and subdirectories
$fileList = Get-ChildItem -Path $directoryPath -Recurse | Where-Object { -Not $_.PSIsContainer }

# Create a hashtable to store file hashes
$fileHashes = @{}

# Loop through each file and compute its hash
foreach ($file in $fileList) {
    $hash = Get-FileHash -Path $file.FullName -Algorithm SHA256
    if ($fileHashes.ContainsKey($hash.Hash)) {
        $fileHashes[$hash.Hash] += $file
    } else {
        $fileHashes[$hash.Hash] = @($file)
    }
}

# Create an array to store duplicate file information
$duplicateFiles = @()

# Loop through the hashtable and find duplicate files
foreach ($hash in $fileHashes.Keys) {
    if ($fileHashes[$hash].Count -gt 1) {
        foreach ($file in $fileHashes[$hash]) {
            $duplicateInfo = [PSCustomObject]@{
                "FileName"      = $file.FullName
                "LastModified"  = $file.LastWriteTime
            }
            $duplicateFiles += $duplicateInfo
        }
    }
}

# Specify the output CSV file path
$outputCsv = "DuplicateFiles.csv"

# Export the duplicate file information to a CSV file
$duplicateFiles | Export-Csv -Path $outputCsv -NoTypeInformation

Write-Host "Duplicate file information has been exported to $outputCsv"
