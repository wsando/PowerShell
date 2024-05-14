#this script will crawl the specified path and retrive a list and include last modified date


# Prompt the user to enter a directory path
$directoryPath = Read-Host "Enter the directory path"

# Check if the directory exists
if (-Not (Test-Path -Path $directoryPath)) {
    Write-Host "The specified directory does not exist."
    exit
}

# Get all files in the directory and subdirectories
$fileList = Get-ChildItem -Path $directoryPath -Recurse | Where-Object { -Not $_.PSIsContainer }

# Create an array to store file information
$fileInfoArray = @()

# Loop through each file and gather information
foreach ($file in $fileList) {
    $fileInfo = [PSCustomObject]@{
        "FileName"        = $file.FullName
        "LastModified"    = $file.LastWriteTime
        "Size"            = $file.Length
        "Type"            = $file.Extension
    }
    $fileInfoArray += $fileInfo
}

# Specify the output CSV file path
$outputCsv = "FileDetails.csv"

# Export the file information to a CSV file
$fileInfoArray | Export-Csv -Path $outputCsv -NoTypeInformation

Write-Host "File information has been exported to $outputCsv"
