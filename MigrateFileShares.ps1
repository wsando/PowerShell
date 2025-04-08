# This script will move file shares from one windows server to another
# Exports SMB share configurations from Windows Server 2012 R2.
# Copies all files and folders while preserving permissions using Robocopy.
# Imports SMB share configurations into Windows Server 2022.
# Performs a final delta sync to capture recent file changes.
# Tests share access and logs the results.

# Define source and destination servers
$OldServer = "OldServerName"  # Change to your old server name
$NewServer = "NewServerName"  # Change to your new server name

# Define migration paths
$ExportPath = "C:\MigrationData"
$RobocopyLog = "C:\MigrationLog.txt"

# Step 1: Export SMB Share Configuration from Old Server
Write-Host "Exporting SMB shares from $OldServer..."
Invoke-Command -ComputerName $OldServer -ScriptBlock {
    if (!(Test-Path $using:ExportPath)) {
        New-Item -ItemType Directory -Path $using:ExportPath -Force
    }
    Export-SmigServerSetting -FeatureID FS-SMBShare -Path $using:ExportPath -Verbose
} -Credential (Get-Credential)

# Copy export data to new server
Write-Host "Copying migration data to $NewServer..."
Copy-Item "\\$OldServer\C$\MigrationData" -Destination "C:\" -Recurse -Force

# Get the list of shares
$Shares = Get-SmbShare | Where-Object { $_.Name -ne "IPC$" -and $_.Name -ne "ADMIN$" -and $_.Name -ne "C$" }

# Step 2: Migrate File Data with Robocopy
foreach ($Share in $Shares) {
    $SourcePath = "\\$OldServer\$($Share.Name)"
    $DestinationPath = "D:\$($Share.Name)"  # Change to the appropriate drive

    Write-Host "Migrating files from $SourcePath to $DestinationPath..."
    
    # Create the directory if it doesn’t exist
    if (!(Test-Path $DestinationPath)) {
        New-Item -ItemType Directory -Path $DestinationPath -Force
    }

    # Robocopy with permissions and logs
    robocopy $SourcePath $DestinationPath /E /COPY:DATSOU /DCOPY:T /R:1 /W:1 /LOG:$RobocopyLog /MT:16 /XO
}

# Step 3: Import SMB Share Configuration on New Server
Write-Host "Importing SMB share configurations to $NewServer..."
Import-SmigServerSetting -FeatureID FS-SMBShare -Path $ExportPath -Verbose

# Step 4: Run a Final Sync for Recent Changes
Write-Host "Performing a final sync to capture recent changes..."
foreach ($Share in $Shares) {
    $SourcePath = "\\$OldServer\$($Share.Name)"
    $DestinationPath = "D:\$($Share.Name)"  # Ensure this matches your previous destination

    robocopy $SourcePath $DestinationPath /E /COPY:DATSOU /DCOPY:T /R:1 /W:1 /LOG:$RobocopyLog /MT:16 /XO
}

# Step 5: Test Share Access
Write-Host "Testing SMB share access..."
foreach ($Share in $Shares) {
    $TestPath = "\\$NewServer\$($Share.Name)"
    if (Test-Path $TestPath) {
        Write-Host "SUCCESS: Share $($Share.Name) is accessible at $TestPath"
    } else {
        Write-Host "ERROR: Share $($Share.Name) is NOT accessible at $TestPath"
    }
}

Write-Host "Migration complete. Check the log file: $RobocopyLog"
