# Prompt for input path
$sourcePath = Read-Host "Enter the full path of the folder to scan for SharePoint Online migration"

# Check if path exists
if (-not (Test-Path -Path $sourcePath)) {
    Write-Error "The specified path does not exist."
    exit
}

# Define SharePoint constraints
$illegalChars = [regex]::Escape('~"#%&*:<>?/\\{|}')
$blockedExtensions = @(".ade",".adp",".app",".asp",".bas",".bat",".cer",".chm",".cmd",".com",".cpl",".crt",
                       ".csh",".der",".exe",".fxp",".gadget",".hlp",".hta",".inf",".ins",".isp",".its",
                       ".jar",".jse",".ksh",".lnk",".mad",".maf",".mag",".mam",".maq",".mar",".mas",".mat",
                       ".mau",".mav",".maw",".mda",".mdb",".mde",".mdt",".mdw",".mdz",".msc",".msh",".msh1",
                       ".msh2",".mshxml",".msi",".msp",".mst",".ops",".pcd",".pif",".pl",".prf",".prg",".ps1",
                       ".ps1xml",".ps2",".ps2xml",".psc1",".psc2",".pst",".reg",".rem",".scf",".scr",".sct",
                       ".shb",".shs",".tmp",".url",".vb",".vbe",".vbs",".vsmacros",".vsw",".ws",".wsc",
                       ".wsf",".wsh",".xbap",".xnk")
$reservedNames = @("CON","PRN","AUX","NUL","COM1","COM2","COM3","COM4","COM5","COM6","COM7","COM8","COM9",
                   "LPT1","LPT2","LPT3","LPT4","LPT5","LPT6","LPT7","LPT8","LPT9")

# Output file path
$outputPath = "C:\Script\SPO-FileMigration_Preflight.csv"

# Ensure output directory exists
$outputDir = Split-Path -Path $outputPath
if (-not (Test-Path -Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir | Out-Null
}

# Initialize results
$results = @()

# Begin scanning
Get-ChildItem -Path $sourcePath -Recurse -Force | ForEach-Object {
    $itemPath = $_.FullName
    $relativePath = $itemPath.Substring($sourcePath.Length).TrimStart('\')
    $issues = @()

    # Illegal characters
    if ($_.Name -match "[$illegalChars]") {
        $issues += "Illegal characters in name"
    }

    # Path too long
    if ($itemPath.Length -gt 400) {
        $issues += "Path length > 400 characters"
    }

    # Blocked extensions
    if (-not $_.PSIsContainer -and $blockedExtensions -contains $_.Extension.ToLower()) {
        $issues += "Blocked file extension"
    }

    # File size check (>250MB is risky)
    if (-not $_.PSIsContainer -and $_.Length -gt 262144000) {
        $issues += "File size > 250MB"
    }

    # Leading/trailing space or period in name
    if ($_.Name -match "^\s|\s$|^\.+|\.+$") {
        $issues += "Name has leading/trailing space or period"
    }

    # Reserved name check (for file or folder names only, case-insensitive)
    $nameNoExt = [System.IO.Path]::GetFileNameWithoutExtension($_.Name)
    if ($reservedNames -contains $nameNoExt.ToUpper()) {
        $issues += "Reserved file name"
    }

    # If no issues
    if ($issues.Count -eq 0) {
        $issues += "OK"
    }

    # Record the result
    $results += [PSCustomObject]@{
        ItemType     = if ($_.PSIsContainer) { "Folder" } else { "File" }
        Name         = $_.Name
        RelativePath = $relativePath
        FullPath     = $itemPath
        Issues       = ($issues -join "; ")
    }
}

# Export to CSV
$results | Export-Csv -Path $outputPath -NoTypeInformation -Encoding UTF8

Write-Host "Migration preflight scan complete."
Write-Host "Results saved to: $outputPath"