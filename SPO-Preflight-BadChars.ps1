#This script will ask for a root folder,  and then replace all illegal characters in teh path with -  so that the folder can be migrated to SharePoint Online
# Prompt for input path
$sourcePath = Read-Host "Enter the full path of the folder to sanitize"

# Check if path exists
if (-not (Test-Path -Path $sourcePath)) {
    Write-Error "The specified path does not exist."
    exit
}

# Define illegal characters for SharePoint Online
$illegalPattern = '[~"#%&*:<>?/\\{|}]'

# Function to sanitize name
function Rename-ItemIfNeeded {
    param (
        [string]$itemPath
    )

    $parent = Split-Path $itemPath -Parent
    $name = Split-Path $itemPath -Leaf

    if ($name -match $illegalPattern) {
        $newName = ($name -replace $illegalPattern, '-')
        $newPath = Join-Path $parent $newName

        # Avoid conflict
        if (-not (Test-Path $newPath)) {
            Rename-Item -Path $itemPath -NewName $newName
            Write-Host "Renamed:`n -> From: $itemPath`n -> To:   $newPath`n"
        } else {
            Write-Warning "Skipped: Target name already exists: $newPath"
        }
    }
}

# Process folders first (deepest first to avoid path conflicts)
Get-ChildItem -Path $sourcePath -Recurse -Directory -Force | Sort-Object -Property FullName -Descending | ForEach-Object {
    Rename-ItemIfNeeded -itemPath $_.FullName
}

# Then process files
Get-ChildItem -Path $sourcePath -Recurse -File -Force | ForEach-Object {
    Rename-ItemIfNeeded -itemPath $_.FullName
}

Write-Host "Sanitization complete. All illegal characters replaced with hyphens."