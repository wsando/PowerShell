# This script will clean GPO objects removing empty or legacy extension. To test and see what would be deleted toggle Dry Run to true, to run and delete set to false.
# Define domain and SYSVOL path
$domain = (Get-ADDomain).DNSRoot
$sysvolPath = "\\$domain\SYSVOL\$domain\Policies"

# Define extension folders typically safe to remove if empty
$targetExtensions = @(
    "Machine\Software\Microsoft\Windows\CurrentVersion\Group Policy\Software Installation",
    "User\Software\Microsoft\Windows\CurrentVersion\Group Policy\Software Installation",
    "User\Microsoft\Internet Explorer Maintenance",
    "Machine\Microsoft\RemoteInstall",
    "User\Preferences"
)

# Toggle Dry Run mode
$dryRun = $true  # <<< Set to $false to actually delete

# Optional: Backup GPOs (still active even in dry run for safety if you want)
$backupPath = "C:\GPO_Backups"
if (!(Test-Path $backupPath)) { New-Item -Path $backupPath -ItemType Directory }

$gpos = Get-GPO -All

foreach ($gpo in $gpos) {
    Write-Host "Checking GPO: $($gpo.DisplayName)" -ForegroundColor Cyan
    $gpoPath = Join-Path $sysvolPath $gpo.Id.ToString()

    foreach ($extension in $targetExtensions) {
        $fullExtensionPath = Join-Path $gpoPath $extension

        if (Test-Path $fullExtensionPath) {
            $files = Get-ChildItem -Path $fullExtensionPath -Recurse -Force -ErrorAction SilentlyContinue

            if ($files.Count -eq 0) {
                Write-Host "Empty extension found: $fullExtensionPath" -ForegroundColor Yellow

                if ($dryRun) {
                    Write-Host "Dry Run: Would have deleted $fullExtensionPath" -ForegroundColor Magenta
                }
                else {
                    # Backup the GPO before deleting anything
                    Backup-GPO -Guid $gpo.Id -Path $backupPath -ErrorAction SilentlyContinue

                    # Delete the empty folder
                    Remove-Item -Path $fullExtensionPath -Force -Recurse
                    Write-Host "Deleted: $fullExtensionPath" -ForegroundColor Green
                }
            } else {
                Write-Host "Extension $fullExtensionPath contains files — not deleting." -ForegroundColor Gray
            }
        }
    }
}

Write-Host "`n✅ Cleanup process completed." -ForegroundColor Green
