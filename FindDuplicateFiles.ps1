# This script will find duplicate files in the path specified supporting
# Long file names. It using hasing to find dups not just names.


# Define the folder to scan (modify as needed)
$FolderPath = "D:\YourFolder"  # Change this to your target directory
$OutputCSV = "C:\DuplicateFiles.csv"

# Hash table to store file hashes
$FileHashes = @{}
$DuplicateFiles = @()

# Function to calculate SHA256 hash of a file
Function Get-FileHashSHA256($FilePath) {
    try {
        # Use long path prefix for accessing the file
        $LongPath = "\\?\$FilePath"

        # Read file stream and compute hash
        $Stream = [System.IO.File]::OpenRead($LongPath)
        $Hasher = [System.Security.Cryptography.SHA256]::Create()
        $HashBytes = $Hasher.ComputeHash($Stream)
        $Stream.Close()

        return ([BitConverter]::ToString($HashBytes) -replace "-", "").ToLower()
    } catch {
        Write-Host "Error processing file: $FilePath`n$_" -ForegroundColor Red
        return $null
    }
}

# Get all files in the directory (recursively, ignoring access errors)
Write-Host "Scanning files in $FolderPath..."
$Files = Get-ChildItem -Path $FolderPath -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.FullName.Length -lt 32767 }

# Process each file
foreach ($File in $Files) {
    $FilePath = $File.FullName  # No \\?\ prefix here for Get-ChildItem results

    $Hash = Get-FileHashSHA256 -FilePath $FilePath
    if ($Hash) {
        if ($FileHashes.ContainsKey($Hash)) {
            # Duplicate found
            $DuplicateFiles += [PSCustomObject]@{
                OriginalFile = $FileHashes[$Hash]
                DuplicateFile = $FilePath
                FileSize = $File.Length
            }
        } else {
            # Store hash for first occurrence
            $FileHashes[$Hash] = $FilePath
        }
    }
}

# Output results
if ($DuplicateFiles.Count -gt 0) {
    $DuplicateFiles | Export-Csv -Path $OutputCSV -NoTypeInformation
    Write-Host "Duplicate files found! Results saved to $OutputCSV" -ForegroundColor Green
} else {
    Write-Host "No duplicate files found." -ForegroundColor Yellow
}
