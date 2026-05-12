#This script takes a list of servers and checks to see if they are alive
# Define file paths
$inputFile = "C:\Scripts\servers.txt"
$outputFile = "C:\Scripts\ping_results.csv"
# Initialize output array
$results = @()
# Read PC names from file
$pcNames = Get-Content -Path $inputFile
foreach ($pc in $pcNames) {
   $isOnline = Test-Connection -ComputerName $pc -Quiet -Count 1 -ErrorAction SilentlyContinue
   $status = if ($isOnline) { "Online" } else { "Offline" }
   # Create object for output
   $results += [PSCustomObject]@{
       ComputerName = $pc
       Status = $status
       Timestamp = (Get-Date)
   }
}
# Export results to CSV
$results | Export-Csv -Path $outputFile -NoTypeInformation -Encoding UTF8
Write-Host "Ping results saved to $outputFile" -ForegroundColor Green