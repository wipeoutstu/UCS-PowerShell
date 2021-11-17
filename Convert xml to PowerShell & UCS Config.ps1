<# UCS XML commands can be collected from the UCS HTML GUI by pressing Record XML (which will be exposed in the GUI after pressing the command sequence of Ctrl + Alt + q)
    Perform the task you want to convert to PowerShell in the UCSM GUI, and save the recording. Then connect to your ucs manager via UCS PowerTool:
         
    Now run the following command to expose the PowerShell equivalent of the task(s) you completed in the GUI:
        ConvertTo-UcsCmdlet -Xml -LiteralPath C:\Users\ucs-admin\Desktop\{filename}.log
    
    You can now connect to your UCSM, run the PowerShell commands then disconnect from your UCS PowerTool connection to UCSM:
        Connect-Ucs {UCS IP}
        DisConnect-Ucs
#>

#Create LAN Connectivity Policy
Start-UcsTransaction
$mo = Get-UcsOrg -Level root  | Add-UcsVnicLanConnPolicy -Descr "ESXi iSCSI Boot LanConPol - NEW" -Name "esxi-iSCSI-NEW"
$mo_1 = $mo | Add-UcsVnic -AdaptorProfileName "VMWare" -Name "00_mgmt" -NwTemplName "00_vnic_mgmt" -Order "1"
$mo_2 = $mo | Add-UcsVnic -AdaptorProfileName "VMWare" -Name "01_vmotion" -NwTemplName "01_vnic_vmotion" -Order "2"
$mo_3 = $mo | Add-UcsVnic -AdaptorProfileName "VMWare" -Name "03_vcenterha" -NwTemplName "03_vnic_vcentrha" -Order "3"
$mo_4 = $mo | Add-UcsVnic -AdaptorProfileName "VMWare" -Name "04_lan" -NwTemplName "04_vnic_lan" -Order "4"
$mo_5 = $mo | Add-UcsVnic -AdaptorProfileName "VMWare" -Name "05_New1" -NwTemplName "05_vnic_New1" -Order "5"
$mo_6 = $mo | Add-UcsVnic -AdaptorProfileName "VMWare" -Name "06_New2" -NwTemplName "05_vnic_New2" -Order "6"
$mo_7 = $mo | Add-UcsVnic -AdaptorProfileName "VMWare" -Name "xx_iscsi" -NwTemplName "xx_iscsiboot" -Order "7"
$mo_8 = $mo | Add-UcsVnicIScsiLCP -Name "xx_iscsiboot" -VnicName "xx_iscsi"
$mo_8_1 = $mo_8 | Add-UcsVnicVlan -ModifyPresent -Name "" -VlanName "30_iSCSI"
Complete-UcsTransaction

#Create vNIC Template
Start-UcsTransaction
$mo = Get-UcsOrg -Level root  | Add-UcsVnicTemplate -Descr "New vNIC Template" -IdentPoolName "default" -Name "05_vnic_New2" -NwCtrlPolicyName "default" -SwitchId "B" -TemplType "updating-template"
$mo_1 = $mo | Add-UcsVnicInterface -ModifyPresent -DefaultNet "no" -Name "40_vCenterHA"
$mo_2 = $mo | Add-UcsVnicInterface -ModifyPresent -DefaultNet "no" -Name "50_LAN"
Complete-UcsTransaction

#Create Primary Vnic Templates
$pVnics = Import-Excel -Path C:\UCSPS\UCS.xlsx -WorksheetName pVNICs
ForEach ($pVnic in $pVnics) {
    $Name = $pVnic.Name
    $Descr = $pvnic.Descr
    $TempType = $pVnic.TempType
    $MTU = $pVnic.MTU
    $NetCon = $pVnic.NetConPol
    $Type = $pVnic.Type
    $Mac = $pVnic.MacPool

    Get-UcsOrg -Level root  | Add-UcsVnicTemplate -Descr $Descr -TemplType $TempType -IdentPoolName $Mac -Mtu $MTU -Name $Name -NwCtrlPolicyName $NetCon -RedundancyPairType $Type
}

#Create Secondary Vnic Templates
$sVnics = Import-Excel -Path C:\UCSPS\UCS.xlsx -WorksheetName sVNICs
ForEach ($sVnic in $sVnics) {
    $Name = $sVnic.Name
    $Peer = $sVnic.Peer
    $Descr = $svnic.Descr
    $Type = $sVnic.Type
    $Mac = $sVnic.MacPool
    
    Get-UcsOrg -Level root  | Add-UcsVnicTemplate $Descr -IdentPoolName $Mac -Name $Name -PeerRedundancyTemplName $Peer -RedundancyPairType $Type
}

#Add VLANs to Vnic Templates
$vnvs = Import-Excel -Path C:\UCSPS\UCS.xlsx -WorksheetName vlantemp
ForEach ($vnv in $vnvs) {
    $Name = $vnv.vnic
    $vnic = $vnv.vlan
    $default = $vnv.default

    Start-UcsTransaction
    $mo = Get-UcsOrg -Level root | Add-UcsVnicTemplate -ModifyPresent -Name $Name
    $mo_1 = $mo | Add-UcsVnicInterface -ModifyPresent -DefaultNet $default -Name $vnic -XtraProperty 
    Complete-UcsTransaction
}

#Create MAC Pools
$Macs = Import-Excel -Path "C:\Users\ucs-admin\Desktop\UCS PowerShell\UCS.xlsx" -WorksheetName MACs
ForEach ($Mac in $Macs) {
    $PoolName = $Mac.PoolName
    $Description = $Mac.Description
    $Order = $Mac.Order
    $Start = $Mac.StartAddr
    $End = $Mac.EndAddr

    Start-UcsTransaction
    $mo = Get-UcsOrg -Level root  | Add-UcsMacPool -AssignmentOrder $Order -Descr $Description -Name $PoolName
    $mo_1 = $mo | Add-UcsMacMemberBlock -From $Start -To $End
    Complete-UcsTransaction
}

#Create Maintenance Policy
$Maints = Import-Excel -Path C:\UCSPS\UCS.xlsx -WorksheetName MaintPol
ForEach ($Maint in $Maints) {
    $PolName = $Maint.PolName
    $Descr = $Maint.Descr
    $ShutTimer = $Maint.ShutTimer
    $StoragePol = $Maint.StoragePol
    $RebootPol = $Maint.RebootPol
    $Trigger = $Maint.Trigger
    
    Get-UcsOrg -Level root  | Add-UcsMaintenancePolicy -DataDisr $StoragePol -Descr $Descr -Name $PolName -SoftShutdownTimer $ShutTimer -UptimeDisr $RebootPol -TriggerConfig $Trigger
}



<#Create LAN Connectivity Policy (Original)
Start-UcsTransaction
$mo = Get-UcsOrg -Level root  | Add-UcsVnicLanConnPolicy -Descr "ESXi iSCSI Boot LanConPol" -Name "esxi-iSCSI-boot"
$mo_1 = $mo | Add-UcsVnic -AdaptorProfileName "VMWare" -Name "00_mgmt" -NwTemplName "00_vnic_mgmt" -Order "1"
$mo_2 = $mo | Add-UcsVnic -AdaptorProfileName "VMWare" -Name "01_vmotion" -Order "2"
$mo_3 = $mo | Add-UcsVnic -AdaptorProfileName "VMWare" -Name "03_vcenterha" -NwTemplName "03_vnic_vcentrha" -Order "3"
$mo_4 = $mo | Add-UcsVnic -AdaptorProfileName "VMWare" -Name "04_lan" -NwTemplName "04_vnic_lan" -Order "4"
$mo_5 = $mo | Add-UcsVnic -AdaptorProfileName "VMWare" -Name "xx_iscsi" -NwTemplName "xx_iscsiboot" -Order "5"
$mo_6 = $mo | Add-UcsVnicIScsiLCP -Name "xx_iscsiboot" -VnicName "xx_iscsi"
$mo_6_1 = $mo_6 | Add-UcsVnicVlan -ModifyPresent -Name "" -VlanName "30_iSCSI"
Complete-UcsTransaction
#>


