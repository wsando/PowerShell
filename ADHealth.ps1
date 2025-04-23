# This script will generate a table of all domain controllers and do a basic health and replication check

# Requires RSAT tools (ActiveDirectory module) and repadmin.exe

$domainControllers = Get-ADDomainController -Filter *

$results = foreach ($dc in $domainControllers) {
    $repStatus = (repadmin /replsummary | Select-String $dc.HostName) -join ', '
    
    [PSCustomObject]@{
        Name              = $dc.Name
        Site              = $dc.Site
        OSVersion         = $dc.OperatingSystem
        IPv4Address       = $dc.IPv4Address.IPAddressToString
        IsGlobalCatalog   = $dc.IsGlobalCatalog
        IsReadOnly        = $dc.IsReadOnly
        ReplicationStatus = if ($repStatus -match "Fails") { "Warning" } else { "Healthy" }
    }
}

$results | Format-Table

