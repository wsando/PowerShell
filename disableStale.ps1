#This script will ask for a file containing computer accounts, it will then disable the accounts and move them to the Disabled OU

# Import the Active Directory module
Import-Module ActiveDirectory

# Prompt user for the path to the text file containing computer names
$filePath = Read-Host -Prompt "Enter the full path to the text file containing computer names"

# Check if the file exists
if (-Not (Test-Path -Path $filePath)) {
    Write-Host "The specified file does not exist. Please check the path and try again." -ForegroundColor Red
    exit
}

# Read the computer names from the file
$computerNames = Get-Content -Path $filePath

# Define the target OU for disabled accounts
$disabledOU = "OU=DisabledComputers,DC=Domain,DC=com"  # Update with your actual Disabled OU DN

foreach ($computerName in $computerNames) {
    try {
        # Get the computer account from AD
        $computer = Get-ADComputer -Identity $computerName -ErrorAction Stop

        # Disable the computer account
        Set-ADComputer -Identity $computerName -Enabled $false

        # Move the computer account to the Disabled OU
        Move-ADObject -Identity $computer.DistinguishedName -TargetPath $disabledOU

        Write-Host "Successfully disabled and moved: $computerName" -ForegroundColor Green
    } catch {
        Write-Host "Failed to process $computerName. Error: $_" -ForegroundColor Red
    }
}

Write-Host "Processing complete." -ForegroundColor Cyan
