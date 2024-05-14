# Define the root directory to start listing from
$rootDirectory = "C:\Path\To\Root\Directory"

# Function to recursively list directories and subdirectories
function Get-AllDirectories {
    param (
        [string]$path
    )

    # Output the current directory
    Write-Output $path

    # Get all subdirectories
    $subDirectories = Get-ChildItem -Path $path -Directory

    # Recursively list subdirectories
    foreach ($subDir in $subDirectories) {
        Get-AllDirectories -path $subDir.FullName
    }
}

# Call the function to get all directories and subdirectories
$allDirectories = Get-AllDirectories -path $rootDirectory

# Output the list of directories and subdirectories

$allDirectories | Out-File -FilePath "DirList.txt"
