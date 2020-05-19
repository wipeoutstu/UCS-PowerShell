# If you don't have the Import-Excel cmdlet,then use the below

    # Install-Module -Name ImportExcel
    # Import-Module -Name ImportExcel

# Connect to UCS with UCS Powertool - 
    # Connect-UCS {Cluster IP}


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
