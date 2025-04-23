# This script will generate a basic health check on a domain controller. This script gathers information from the server it is run on only

Import-Module ActiveDirectory

# Get local DC info
$hostname = $env:COMPUTERNAME
$dc = Get-ADDomainController -Identity $hostname
$computer = Get-ADComputer $dc.Name -Properties OperatingSystem
$fsmo = netdom query fsmo
$fsmos = ($fsmo -match $dc.HostName) -join ', '
$ip = ($dc.IPv4Address).IPAddressToString
$osVersion = $computer.OperatingSystem

# Parse replication status using repadmin
$replicationRaw = repadmin /showrepl $hostname /errorsonly
if ($replicationRaw -match "0 failures") {
    $replicationHealth = "Healthy"
} elseif ($replicationRaw -match "Last error") {
    $replicationHealth = "Issues Found"
} else {
    $replicationHealth = "Unknown"
}

# Build object
$result = [PSCustomObject]@{
    Name              = $dc.Name
    Site              = $dc.Site
    IPv4Address       = $ip
    OSVersion         = $osVersion
    IsGlobalCatalog   = $dc.IsGlobalCatalog
    IsReadOnly        = $dc.IsReadOnly
    FSMOHolder        = $fsmos
    ReplicationHealth = $replicationHealth
}

# Output and export
$result | Format-List
$result | Export-Csv -Path "$env:USERPROFILE\Desktop\DC_Local_Health_Report.csv" -NoTypeInformation
