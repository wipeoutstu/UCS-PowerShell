#Create VLANs
$VLANs = Import-Excel -Path C:\UCSPS\UCS.xlsx -WorkSheetName VLANs
ForEach ($VLAN in $VLANs) {
    $VLANnum = $VLAN.VLAN
    $VLANdesc = $VLAN.Descr

    Get-UcsLanCloud | Add-UcsVlan -CompressionType "included" -DefaultNet "no" -Id $VLANnum -McastPolicyName "" -Name $VLANdesc -PolicyOwner "local" -PubNwName "" -Sharing "none"
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

#Create MAC Pools
$Macs = Import-Excel -Path C:\UCSPS\UCS.xlsx -WorksheetName MACs
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



Get-UcsLanCloud | Add-UcsVlan -CompressionType "included" -DefaultNet "no" -Id 3 -McastPolicyName "" -Name "sw-3" -PolicyOwner "local" -PubNwName "" -Sharing "none"

Start-UcsTransaction
$mo = Get-UcsLanCloud | Add-UcsFabricNetGroup -ModifyPresent  -Name "esx-vmotion"
$mo_1 = $mo | Add-UcsFabricPooledVlan -ModifyPresent -Name "sw-3"
Complete-UcsTransaction




#Create VLANs & Add them to VLAN Group
$VLANs = Import-Excel -Path C:\UCS\UCS.xlsx -WorkSheetName VLANs
ForEach ($VLAN in $VLANs) {
    $VLANnum = $VLAN.VLAN
    $VLANdesc = $VLAN.Descr
    $VLANgrp = $VLAN.Group

    Get-UcsLanCloud | Add-UcsVlan -CompressionType "included" -DefaultNet "no" -Id $VLANnum -McastPolicyName "" -Name $VLANdesc -PolicyOwner "local" -PubNwName "" -Sharing "none"

    Start-UcsTransaction
    $mo = Get-UcsLanCloud | Add-UcsFabricNetGroup -ModifyPresent  -Name $VLANgrp
    $mo_1 = $mo | Add-UcsFabricPooledVlan -ModifyPresent -Name $VLANdesc
    Complete-UcsTransaction
}