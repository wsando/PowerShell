#This script will return a list of all computers running a Server OS

# Import the Active Directory module
Import-Module ActiveDirectory

# Define the filter to search only for servers (usually Server Operating Systems)
$filter = "(&(objectCategory=computer)(operatingSystem=*Server*))"

# Retrieve the list of servers from Active Directory
$servers = Get-ADComputer -Filter $filter -Property Name, OperatingSystem | Select-Object Name, OperatingSystem

# Display the list of servers
$servers | ForEach-Object {
    Write-Output "Server Name: $($_.Name), OS: $($_.OperatingSystem)"
}