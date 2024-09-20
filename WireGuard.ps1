# These commands to be run and client laptops will allow non-admin users to start and stop tunnels 
# you must install Wireguard as an admin and execute it once as admin to get it ready for these changes

#this command adds the registry key telling wireguard to use the network config op group
New-ItemProperty "hklm:\software\wireguard" -Name "LimitedOperatorUI" -Value 1 -PropertyType "DWord" -Force  

#this command adds the user to the network configuration operators group to use wireguard
Add-LocalGroupMember -Group "Network Configuration Operators" -Member "$username"
