<#
.SYNOPSIS

Microsoft Windows Server to Mikrotik DHCP Migration Tool

.DESCRIPTION

Connects to a specified Windows Server DHCP Server and generates the necessary Mikrotik RSC script to migrate services. Creates Win2Tik bridges to assign each server to allow selection in winbox. Does not automatically apply any settings or disable any settings running the script.

.EXAMPLE

./DHCP-Win2Mikrotik.ps1 -ComputerName SRV-DHCP -OutFile "C:\Users\Bob\Desktop\script.rsc"

.NOTES

Connects to a specified Windows Server DHCP Server and generates the necessary Mikrotik RSC script to migrate services. Creates Win2Tik bridges to assign each server to allow selection in winbox. Does not automatically apply any settings or disable any settings running the script.

.LINK

https://fikesmedia.com
#>

# Required Parameters
param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$ComputerName,
    [Parameter(Mandatory=$true)]
    [string]$OutFile

)


#
# Function to convert Mask to CIDR length
function Convert-MaskToLength([string] $MaskString)
{
  $Result = 0; 
  # ensure we have a valid IP address
  [IPAddress] $IP = $MaskString;
  $Octets = $IP.IPAddressToString.Split('.');
  foreach($Octet in $Octets)
  {
    while(0 -ne $Octet) 
    {
      $Octet = ($Octet -shl 1) -band [byte]::MaxValue
      $result++; 
    }
  }
  return $Result;
}
# End Function
#


# Get Server Options
Add-Content $OutFile "# DHCP server options and option sets"
$ServerOptionsList = Get-DhcpServerv4OptionValue -ComputerName $ComputerName
$DHCPServerOptionsList = ""
$ServerOptionsList | ForEach-Object {

    # Format option value
    If ($_.Type -eq "String") {
        $ThisOptionValue = "'$($_.Value)'"
    } ElseIf ($_.Type -eq "IPv4Address") {
        $Value = $_.Value | Out-String
        $Value = $Value.Replace("`r`n","''")
        $Value = $Value.Substring(0,$Value.Length-2)
        $ThisOptionValue = "'$($Value)'"
    } ElseIf ($_.Type -eq "Hex") {
        $ThisOptionValue = "$($_.Value)"
    } Else {
        $ThisOptionValue = "'$($_.Value)'"
    }

    $DHCPServerOptionsList = "$($DHCPServerOptionsList)$($_.Name),"

    # Create option
    $ThisServerOption = "/ip/dhcp-server/option/add code=$($_.OptionID) name=`"$($_.Name)`" value=`"$($ThisOptionValue)`""
    Add-Content $OutFile $ThisServerOption
       
}

# Add to option set
# Remove last comma
$DHCPServerOptionsList = $DHCPServerOptionsList.Substring(0,$DHCPServerOptionsList.Length-1)
$ThisServerOptionSet = "/ip/dhcp-server/option/sets/add name=`"Win2Tik Server Options`" options=`"$($DHCPServerOptionsList)`""
Add-Content $OutFile $ThisServerOptionSet



# Get all scopes for basic information
$ScopeList = Get-DhcpServerv4Scope -ComputerName $ComputerName

# Bridge Counter
$BridgeCounter = 1

# Loop though all scopes for detail information.
$ScopeList | ForEach-Object {
    # Add Win2Tik bridge for 
    Add-Content $OutFile "`n# Dummy bridge to allow changing interface in Winbox"
    Add-Content $OutFile "/interface/bridge/add name=`"Win2Tik$($BridgeCounter)`""

    # Building scopes and servers
    Add-Content $OutFile "# DHCP Pool and Server"
    # Create IP pool
    $ThisPool = "/ip/pool/add name=dhcp_pool_$($_.ScopeID) ranges=$($_.StartRange)-$($_.EndRange) comment=`"Win2Tik $($_.Name)`""
    Add-Content $OutFile $ThisPool

    # Create network mask
    $ThisDHCPNetworkAddressCIDR = "$(Convert-MaskToLength -MaskString $_.SubnetMask)"

    # Create dhcp network options
    $ThisDHCPNetworkExtras = ""
    $ThisDHCPScopeOptionsList = Get-DhcpServerv4OptionValue -ComputerName $ComputerName -ScopeId $_.ScopeID
    $ThisDHCPScopeOptionsList | ForEach-Object {
        # Gateway
        If ($_.OptionId -eq "3") {
            $ThisDHCPNetworkExtras = "$($ThisDHCPNetworkExtras)gateway=$($_.Value) "
        }
        # DNS Servers
        If ($_.OptionId -eq "6") {
            $Value = $_.Value | Out-String
            $Value = $Value.Replace("`r`n",",")
            $Value = $Value.Substring(0,$Value.Length-1)
            $ThisDHCPNetworkExtras = "$($ThisDHCPNetworkExtras)dns-server=$($Value) "
        }
        # Domain
        If ($_.OptionId -eq "15") {
            $ThisDHCPNetworkExtras = "$($ThisDHCPNetworkExtras)domain=$($_.Value) "
        }
        # WINS
        If ($_.OptionId -eq "44") {
            $Value = $_.Value | Out-String
            $Value = $Value.Replace("`r`n",",")
            $Value = $Value.Substring(0,$Value.Length-1)
            $ThisDHCPNetworkExtras = "$($ThisDHCPNetworkExtras)wins-server=$($Value) "
        }
        # NTP
        If ($_.OptionId -eq "42") {
            $Value = $_.Value | Out-String
            $Value = $Value.Replace("`r`n",",")
            $Value = $Value.Substring(0,$Value.Length-1)
            $ThisDHCPNetworkExtras = "$($ThisDHCPNetworkExtras)ntp-server=$($Value) "
        }
        # Next Server
        If ($_.OptionId -eq "66") {
            $ThisDHCPNetworkExtras = "$($ThisDHCPNetworkExtras)next-server=$($_.Value) "
        }
        # Next Server
        If ($_.OptionId -eq "67") {
            $ThisDHCPNetworkExtras = "$($ThisDHCPNetworkExtras)boot-file-name=$($_.Value) "
        }
        # Lease Time
        If ($_.OptionId -eq "51") {
            $ThisDHCPNetworkLeaseTime = $_.Value
        }
        
    }
    
    
    # Create this network
    $ThisNetwork = "/ip/dhcp-server/network/add address=$($_.ScopeId)/$($ThisDHCPNetworkAddressCIDR) netmask=$($ThisDHCPNetworkAddressCIDR) dhcp-option-set=`"Win2Tik Server Options`" $($ThisDHCPNetworkExtras)"
    Add-Content $OutFile $ThisNetwork

    # Create DHCP server
    $ThisDHCPServerName = "dhcp_$($_.ScopeID)"
    $ThisDHCPServer = "/ip/dhcp-server/add name=dhcp_$($_.ScopeID) interface=Win2Tik$($BridgeCounter) address-pool=dhcp_pool_$($_.ScopeID) lease-time=$($ThisDHCPNetworkLeaseTime)"
    Add-Content $OutFile $ThisDHCPServer

    # Create reservations for scope
    $ThisDHCPScopeReservations = Get-DhcpServerv4Reservation -ScopeId $_.ScopeID -ComputerName $ComputerName | Select-Object IPAddress,Clientid,Name
    If ($ThisDHCPScopeReservations.Count -gt 0) {
        Add-Content $OutFile "# DHCP Lease Reservations"
        $ThisDHCPScopeReservations | ForEach-Object {
            $FormattedMAC = $_.Clientid.replace('-',':')
            if ($FormattedMAC.Length -eq 17) {
                Add-Content $OutFile "/ip/dhcp-server/lease/add address=$($_.IPAddress) mac-address=$($FormattedMAC) comment=`"$($_.Name)`" server=$($ThisDHCPServerName) use-src-mac=yes"
            }
        }
    }

$BridgeCounter++
}