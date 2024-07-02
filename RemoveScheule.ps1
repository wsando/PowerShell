#PowerShell script to remove a scheduled task from a list of computers
#Replace TaskName with the name of the scheduled task you want to delete.


$computers = Get-Content -Path "computers.txt"
$taskName = "TaskName"

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
