# Launch by .\last-Modified.ps1 -rootPath "C:\Specific\Directory"

#this script will get the input root path, then cycle through the path
#getting the file last modified date and exporting the list to a CSV in the current folder



# Check if the root path was provided as a command-line argument
param (
    [Parameter(Mandatory=$true)]
    [string]$rootPath
)

# Define the path where the CSV file will be saved
$outputPath = ".\file_list.csv"

# Retrieve all files in the directory and subdirectories
$files = Get-ChildItem -Path $rootPath -Recurse -File

# Select the desired properties (full file path and last write time)
$fileInfo = $files | Select-Object FullName, LastWriteTime

# Export the information to a CSV file
$fileInfo | Export-Csv -Path $outputPath -NoTypeInformation

# Output path of the generated CSV file
Write-Host "CSV file has been saved to $outputPath"

