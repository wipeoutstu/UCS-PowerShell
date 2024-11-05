
# Define UCS Manager credentials and server details
$ucsmHost = "10.20.20.9"
$username = "admin"
$password = "password"

# Connect to UCS Manager
Connect-Ucs -Name $ucsmHost -Credential (New-Object PSCredential ($username, (ConvertTo-SecureString $password -AsPlainText -Force)))

# Get all Service Profiles
$serviceProfiles = Get-UcsServiceProfile

# List the vNICs in the specified Service Profile and export to an Excel Worksheet
foreach ($serviceProfile in $serviceProfiles) {
    Get-UcsVnic -ServiceProfile $serviceProfile | Select-Object Name, Addr, Mtu, Order, OperOrder | Export-Excel "C:\Users\ucs-admin\Desktop\Script-UCS-SPInfo.xlsx" -WorkSheetName $serviceProfile.Name -AutoSize
}

# Disconnect from UCS Manager
Disconnect-Ucs

