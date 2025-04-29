# this script will gather the AutoPilot computer hash from an existing computer and place it in the file specified

#this step lets us run un-signed powershell scripts
Set-ExecutionPolicy RemoteSigned

Install-Script -Name Get-WindowsAutopilotInfo
Get-WindowsAutopilotInfo -OutputFile C:\DeviceHash.csv