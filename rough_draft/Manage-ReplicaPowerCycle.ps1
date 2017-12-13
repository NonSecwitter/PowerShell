<#
    .AUTHOR
        Jonathon Anderson
    .COPYRIGHT 
        Jonathon Anderson

    .SYNOPSIS
        Replication has a tendency to fail when hosts complete a power cycle.
        
        Manage-ReplicaPowerCycle polls the local server for information
        about replication relationships. Using PrimaryServer and 
        ReplicaServer, commands are invoked on the local and remote
        machines to manage replication.
        
        The script works well as a startup/shutdown script, but has other
        applications as well.
    
    .PARAMETER
    .EXAMPLE
    
    .TODO
       Complete testing for suspending replication
       Add ability to resume replication
       Add paramater support
#>

function Manage-ReplicaPowerCycle
{
    [CmdletBinding()]
    Param()

    BEGIN {}

    PROCESS
    {
        $LocalHost = (Get-WmiObject Win32_ComputerSystem).DNSHostName+"."+(Get-WmiObject Win32_ComputerSystem).Domain


        $LocalHost = $LocalHost.ToUpper()

        [System.Collections.ArrayList] $HVServers 
        $HVServers.Clear()

        $Replicas = Get-VMReplication -ComputerName $LocalHost

        $HVServers.AddRange(@($Replicas.PrimaryServer.ToUpper() | Select-Object -Unique))
        $HVservers.AddRange(@($Replicas.ReplicaServer.ToUpper() | Select-Object -Unique))
        $HVServers.Remove($LocalHost)

        Get-VMReplication | Suspend-VMReplication
        Invoke-Command -ComputerName $HVServers -ScriptBlock { Get-VMReplication | Suspend-VMReplication }
    }

    END {}

}
