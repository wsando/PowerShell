# This script will read a text file of computer names, and retrive all
# partitions on the systems

# Path to the text file with server names
$serverListPath = "C:\Path\To\servers.txt"  # Update this path to where your servers.txt file is located

# Read server names from the file
$servers = Get-Content -Path $serverListPath

# Initialize an array to store results
$results = @()

foreach ($server in $servers) {
    try {
        # Retrieve partition information
        $partitions = Get-CimInstance -ComputerName $server -ClassName Win32_LogicalDisk -Filter "DriveType = 3" # DriveType 3 for fixed drives

        foreach ($partition in $partitions) {
            # Calculate used space and total size in GB for readability
            $totalSizeGB = [math]::round($partition.Size / 1GB, 2)
            $usedSpaceGB = [math]::round(($partition.Size - $partition.FreeSpace) / 1GB, 2)
            $freeSpaceGB = [math]::round($partition.FreeSpace / 1GB, 2)

            # Store results in a custom object
            $results += [pscustomobject]@{
                Server      = $server
                Drive       = $partition.DeviceID
                TotalSizeGB = $totalSizeGB
                UsedSpaceGB = $usedSpaceGB
                FreeSpaceGB = $freeSpaceGB
            }
        }
    }
    catch {
        Write-Output "Failed to retrieve data for ${server}: $_"

    }
}

# Display the results
$results | Format-Table -AutoSize

# Optionally, export to CSV
$results | Export-Csv -Path "PartitionInfo.csv" -NoTypeInformation -Encoding UTF8
