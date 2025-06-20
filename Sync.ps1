This script will sync a file share to a remote synology share with stored credentials on the Windows server

# Sync.ps1

$Source = "C:\SourceShare"
$Destination = "\\Synology_IP\TargetShare"
$LogFile = "C:\Logs\SynologySync.log"

# Run robocopy
robocopy $Source $Destination /MIR /Z /FFT /XA:H /W:5 /R:3 /LOG+:$LogFile