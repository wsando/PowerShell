# This script will generate a table of all domain controllers and do a basic health and replication check

Import-Module ActiveDirectory

# Local reference time
$localTime = Get-Date
$fsmo = netdom query fsmo
$domainControllers = Get-ADDomainController -Filter *

$results = foreach ($dc in $domainControllers) {
    $hostname = $dc.HostName
    $ip = ($dc | Select-Object -ExpandProperty IPv4Address).IPAddressToString
    $osVersion = (Get-ADComputer $dc.Name -Properties OperatingSystem).OperatingSystem
    $fsmos = ($fsmo -match $hostname) -join ', '
    $ping = Test-Connection -ComputerName $hostname -Count 1 -Quiet

    if ($ping) {
        try {
            $os = Get-CimInstance -ComputerName $hostname -ClassName Win32_OperatingSystem -ErrorAction Stop
            $uptime = $os.LastBootUpTime
            $currentTime = $os.LocalDateTime
            $parsedTime = [System.Management.ManagementDateTimeConverter]::ToDateTime($currentTime)
            $timeDrift = ($parsedTime - $localTime).TotalSeconds

            $dnsStatus = Get-Service -ComputerName $hostname -Name DNS -ErrorAction SilentlyContinue
            $netlogon = Test-Path -Path "\\$hostname\netlogon"
            $sysvol = Test-Path -Path "\\$hostname\sysvol"

            $repStatus = (repadmin /replsummary | Select-String $hostname) -join ', '

            [PSCustomObject]@{
                Name              = $dc.Name
                Site              = $dc.Site
                IPv4Address       = $ip
                OSVersion         = $osVersion
                IsGlobalCatalog   = $dc.IsGlobalCatalog
                IsReadOnly        = $dc.IsReadOnly
                FSMOHolder        = $fsmos
                Uptime            = $uptime
                TimeDrift_Seconds = [math]::Round($timeDrift, 2)
                DNS_Status        = if ($dnsStatus.Status -eq 'Running') { 'Running' } else { 'Stopped/NotFound' }
                NetlogonShare     = if ($netlogon) { 'Available' } else { 'Missing' }
                SysvolShare       = if ($sysvol) { 'Available' } else { 'Missing' }
                ReplicationStatus = if ($repStatus -match "Fails") { "Warning" } else { "Healthy" }
            }
        } catch {
            [PSCustomObject]@{
                Name              = $dc.Name
                Site              = $dc.Site
                IPv4Address       = $ip
                OSVersion         = $osVersion
                IsGlobalCatalog   = $dc.IsGlobalCatalog
                IsReadOnly        = $dc.IsReadOnly
                FSMOHolder        = $fsmos
                Uptime            = "Error"
                TimeDrift_Seconds = "Error"
                DNS_Status        = "Error"
                NetlogonShare     = "Error"
                SysvolShare       = "Error"
                ReplicationStatus = "Error"
            }
        }
    } else {
        [PSCustomObject]@{
            Name              = $dc.Name
            Site              = $dc.Site
            IPv4Address       = $ip
            OSVersion         = $osVersion
            IsGlobalCatalog   = $dc.IsGlobalCatalog
            IsReadOnly        = $dc.IsReadOnly
            FSMOHolder        = $fsmos
            Uptime            = "Unreachable"
            TimeDrift_Seconds = "Unknown"
            DNS_Status        = "Unreachable"
            NetlogonShare     = "Unreachable"
            SysvolShare       = "Unreachable"
            ReplicationStatus = "Unreachable"
        }
    }
}

# Output results
$results | Format-Table -AutoSize
$results | Export-Csv -Path "Full_DC_Health_Report.csv" -NoTypeInformation
