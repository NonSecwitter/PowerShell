#######################################################
##
## WakeUp-DHCPScope.ps1, v1.1, 2012
##
## Created by Matthijs ten Seldam, Microsoft
##
## Modified to use DHCP by NonSecwitter
## (Originally Titled WakeUp-Machines and relied on a CSV
##  containing all MAC addresses of target machines)
##
#######################################################
 
<#
SYNOPSIS
Starts a list of physical machines by using Wake On LAN.
 
DESCRIPTION
WakeUp-DHCPScope starts a list of servers using Wake On LAN magic packets. It then sends echo requests to verify that the machine has TCP/IP connectivity. It waits for a specified amount of echo replies before starting the next machine in the list.
 
PARAMETER Scope
The DHCP Scope to poll for client leases.
 
PARAMETER TimeOut
The number of seconds to wait for an echo reply before continuing with the next machine.
 
PARAMETER Repeat
The number of echo requests to send before continuing with the next machine.
 
EXAMPLE
WakeUp-DHCPScope 192.168.0.0
 
INPUTS
None
 
OUTPUTS
None
 
NOTES
Make sure the MAC addresses supplied don't contain "-" or ".".

 
LINK
http://blogs.technet.com/matthts
#>
 
 
param(
    [Parameter(Mandatory=$true, HelpMessage="DHCP Scope to poll for client leases.")]
    [string] $Scope,
    [Parameter(Mandatory=$false, HelpMessage="Number of unsuccesful echo requests before continuing.")]
    [int] $TimeOut=8,
    [Parameter(Mandatory=$false, HelpMessage="Number of successful echo requests before continuing.")]
    [int] $Repeat=10,
    [Parameter(Mandatory=$false, HelpMessage="Number of magic packets to send to the broadcast address.")]
    [int] $Packets=2
    )

 
Set-StrictMode -Version Latest

Import-Module DHCPServer

function Send-Packet([string]$MacAddress, [int]$Packets)
{
    <#
    .SYNOPSIS
    Sends a number of magic packets using UDP broadcast.
 
    .DESCRIPTION
    Send-Packet sends a specified number of magic packets to a MAC address in order to wake up the machine.  
 
    .PARAMETER MacAddress
    The MAC address of the machine to wake up.
 
    .PARAMETER Packets
    The number of packets to send.
    #>
 
    try 
    {
        $Broadcast = ([System.Net.IPAddress]::Broadcast)
 
        ## Create UDP client instance
        $UdpClient = New-Object Net.Sockets.UdpClient
 
        ## Create IP endpoints for each port
        $IPEndPoint1 = New-Object Net.IPEndPoint $Broadcast, 0
        $IPEndPoint2 = New-Object Net.IPEndPoint $Broadcast, 7
        $IPEndPoint3 = New-Object Net.IPEndPoint $Broadcast, 9
 
        ## Construct physical address instance for the MAC address of the machine (string to byte array)
        $MAC = [Net.NetworkInformation.PhysicalAddress]::Parse($MacAddress)
 
        ## Construct the Magic Packet frame
        $Frame = [byte[]]@(255,255,255,255,255,255);
        $Frame += ($MAC.GetAddressBytes()*16)
 
        ## Broadcast UDP packets to the IP endpoints of the machine
        for($i = 0; $i -lt $Packets; $i++) {
            $UdpClient.Send($Frame, $Frame.Length, $IPEndPoint1) | Out-Null
            $UdpClient.Send($Frame, $Frame.Length, $IPEndPoint2) | Out-Null
            $UdpClient.Send($Frame, $Frame.Length, $IPEndPoint3) | Out-Null
            sleep 1;
        }
    }
    catch
    {
        $Error | Write-Error;
    }
}

$TempLeasePool = Get-DHCPServerv4Lease $Scope
$LeasePool = New-Object System.Collections.ArrayList
foreach($lease in $TempLeasePool)
{
    $null = $LeasePool.add($lease)
}

for ($i = 0; $i -lt 2; $i++)
{
    foreach($Lease in $LeasePool)
    {
        $MacAddress= ($Lease.ClientID -replace '-','').ToUpper()
        $IPAddress=$Lease.IPAddress.IPAddressToString
    
        Send-Packet $MacAddress $Packets
    }

    foreach($Lease in $LeasePool.ToArray())
    {
        $Ping = New-Object System.Net.NetworkInformation.Ping
        
        $IPAddress=$Lease.IPAddress.IPAddressToString

        for ($i = 0; $i -lt $timeout; $i++)
        {
            $Echo = $Ping.Send($IPAddress)
        }

        if ($Echo.Status.ToString() -eq "Success") 
        {
            $LeasePool.Remove($lease);
        }

        $Ping=$null
    }

    Sleep 300
}



    
$LogName = "C:\WOLLogs\" + (Get-Date -Format MMddyyyy) + ".txt"
New-Item C:\WOLLogs -ItemType Directory -ErrorAction SilentlyContinue
$Log = New-Item $LogName -ItemType File
$LeasePool > $Log
