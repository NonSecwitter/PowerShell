<#
    .AUTHOR
        Jonathon Anderson
    .COPYRIGHT 
        Jonathon Anderson

    .SYNOPSIS
        Hyper-V Replication has a tendency to fail when hosts complete a power cycle.
        
        Manage-ReplicaPowerCycle polls the local server for information
        about replication relationships. Using PrimaryServer and 
        ReplicaServer, commands are invoked on the local and remote
        machines to manage replication. 

        The script works well as a startup/shutdown script and can be deployed on primary
        and replica servers without modification, but has other applications as well.

    .PARAMETER
    .EXAMPLE
    .TODO
       Are $VMReplica.PrimaryServer and $VMReplica.ReplicaServer always FQDN?
#>

#function Manage-ReplicaPowerCycle
#{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true,ParameterSetName="SuspendReplication")]
        [switch]$SuspendReplication,

        [Parameter(Mandatory=$true,ParameterSetName="ResumeReplication")]
        [switch]$ResumeReplication
    )

    BEGIN {}

    PROCESS
    {
        $LocalHost = (Get-WmiObject Win32_ComputerSystem).DNSHostName+"."+(Get-WmiObject Win32_ComputerSystem).Domain

        $LocalHost = $LocalHost.ToUpper()

        [System.Collections.ArrayList] $HVServers = @()

        $Replicas = Get-VMReplication -ComputerName $LocalHost

        $HVServers.AddRange(@($Replicas.PrimaryServer.ToUpper() | Select-Object -Unique))
        $HVservers.AddRange(@($Replicas.ReplicaServer.ToUpper() | Select-Object -Unique))

        if($SuspendReplication)
        {
            Invoke-Command -ComputerName $HVServers -ScriptBlock { Get-VMReplication | Suspend-VMReplication }
        }
        elseif($ResumeReplication)
        {
            Invoke-Command -ComputerName $HVServers -ScriptBlock { Get-VMReplication | Resume-VMReplication }
        }
    }

    END {}
#}
