# This script will generate a table of all domain controllers and do a basic health and replication check

Import-Module ActiveDirectory

# Set reference time for drift check
$localTime = Get-Date
$domainControllers = Get-ADDomainController -Filter *
$fsmo = netdom query fsmo

$results = foreach ($dc in $domainControllers) {
    $ping = Test-Connection -ComputerName $dc.HostName -Count 1 -Quiet
    $fsmos = ($fsmo -match $dc.HostName) -join ', '

    if ($ping) {
        try {
            $os = Get-CimInstance -ComputerName $dc.HostName -ClassName Win32_OperatingSystem
            $uptime = $os.LastBootUpTime
            $currentTime = [datetime]::ParseExact($os.LocalDateTime, "yyyyMMddHHmmss.000000+000", $null)
            $timeDrift = ($currentTime - $localTime).TotalSeconds

            $dnsStatus = Get-Service -ComputerName $dc.HostName -Name DNS -ErrorAction SilentlyContinue

            $netlogon = Test-Path -Path "\\$($dc.HostName)\netlogon"
            $sysvol = Test-Path -Path "\\$($dc.HostName)\sysvol"

            $repStatus = (repadmin /replsummary | Select-String $dc.HostName) -join ', '

            [PSCustomObject]@{
                Name              = $dc.Name
                Site              = $dc.Site
                IPv4Address       = $dc.IPv4Address.IPAddressToString
                OSVersion         = $dc.OperatingSystem
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
                IPv4Address       = $dc.IPv4Address.IPAddressToString
                OSVersion         = "Error"
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
            IPv4Address       = $dc.IPv4Address.IPAddressToString
            OSVersion         = "Unreachable"
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

# Display results
$results | Format-Table -AutoSize

# Optional export
$results | Export-Csv -Path "Full_DC_Health_Report.csv" -NoTypeInformation
