# This script will query local AD server to find users that have logged in on the named computer

Get-WinEvent -LogName Security |
Where-Object {
    $_.Id -eq 4624 -and
    $_.Properties[18].Value -eq "PC-NAME"
} | Select-Object TimeCreated, @{Name="User";Expression={$_.Properties[5].Value}}, @{Name="Workstation";Expression={$_.Properties[18].Value}}