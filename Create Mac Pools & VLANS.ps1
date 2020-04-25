# If you don't have the Import-Excel cmdlet,then use the below

    # Install-Module -Name ImportExcel
    # Import-Module -Name ImportExcel

# Connect to UCS with UCS Powertool - 
    # Connect-UCS {Cluster IP}

# Edit the path to the Excel Workbook & sheet name


# Create VLANs & Add them to VLAN Group
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


#Create MAC Pools
$Macs = Import-Excel -Path C:\UCS\UCS.xlsx -WorksheetName MACs
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


