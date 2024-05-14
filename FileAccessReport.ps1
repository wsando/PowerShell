# Define the directory path to search
$directoryPath = "C:\Path\To\Your\Directory"

# Function to recursively get files and their last access time
function Get-FilesLastAccessTime {
    param (
        [string]$path
    )

    # Get all files in the current directory
    $files = Get-ChildItem -Path $path -File

    # Output file information
    foreach ($file in $files) {
        [PSCustomObject]@{
            FileName = $file.FullName
            LastAccessTime = $file.LastAccessTime
        }
    }

    # Recursively get files in subdirectories
    $subDirectories = Get-ChildItem -Path $path -Directory
    foreach ($subDir in $subDirectories) {
        Get-FilesLastAccessTime -path $subDir.FullName
    }
}

# Call the function to get file information recursively
$fileReport = Get-FilesLastAccessTime -path $directoryPath

# Output the report
$fileReport | Export-Csv -Path "FileAccessReport.csv" -NoTypeInformation
