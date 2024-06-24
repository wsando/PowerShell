#This task will ask for the name of the task to remove, then get a list of all computers in AD, and will execute the removal of the task
#To run .\Remove-ScheduledTaskFromAD.ps1 then enter the name of the task when prompted.


Import-Module ActiveDirectory

# Prompt for the task name
$taskName = Read-Host -Prompt "Enter the name of the scheduled task to delete"

# Get the list of computers from Active Directory
$computers = Get-ADComputer -Filter * | Select-Object -ExpandProperty Name

foreach ($computer in $computers) {
    try {
        Invoke-Command -ComputerName $computer -ScriptBlock {
            param ($taskName)
            Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
        } -ArgumentList $taskName -Credential (Get-Credential)
        Write-Host "Successfully deleted task on $computer"
    } catch {
        Write-Host "Failed to delete task on $computer"
    }
}
