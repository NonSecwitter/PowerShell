<#
    .AUTHOR
        Jonathon Anderson
    .COPYRIGHT 
        Jonathon Anderson
    .SYNOPSIS
        Archive-RedirectedFolders aids in user termination by polling Active Directory
        for current users and comparing them to folders in your redirected folders
        repository. Folders that do not have an associated user in Active Directory
        are then migrated to your long term storage or deleted.

        The user account used to run this script currently needs permissions to:
            1) Create remote session with DC (specifically GC)
            2) Execute Get-ADUser on DC
            4) Read/Delete in Redirected Folders Repo ("Move" requires "Delete")
            6) Read/Write in Archive Repo

    .PARAMETER
    .EXAMPLE
        Archive-RedirectedFolders -Domain <domain1>,[<domain2>,<domain3>,...] -RedirectedFolderRoot <root1>,[<root2,<root3>,...] -ArchiveRoot <archive dir root>
    .TODO
        log results
        gather redirection info from GPP
        same samAccountName, different UPN, same folder repo
        eliminate need to invoke-command { get-aduser } without depending on ActiveDirectory module
#>

function Archive-RedirectedFolders
{

    [CmdletBinding(DefaultParameterSetName="Archive")]
    Param 
    (
        [Parameter(Mandatory=$true,ParameterSetName="Archive")]
        [Parameter(Mandatory=$true,ParameterSetName="Delete")]
        [string[]]$Domain,

        [Parameter(Mandatory=$true,ParameterSetName="Archive")]
        [Parameter(Mandatory=$true,ParameterSetName="Delete")]
        [string[]]$RedirectedFolderRoot,

        [Parameter(Mandatory=$true,ParameterSetName="Archive")]
        [string]$ArchiveRoot,

        [Parameter(Mandatory=$true,ParameterSetName="Delete")]
        [switch]$Delete
    )

    BEGIN 
    {
        [System.Collections.ArrayList] $ExistingUsers = @()
        
        [System.Collections.ArrayList] $DNSResults = @()
        foreach ($Dom in $Domain)
        {
            # Find a GC in each domain
            $GCRecord = "_ldap._tcp.gc._msdcs."+$Dom
            $GC = (Resolve-DnsName -Type SRV -Name $GCRecord | Where-Object { $_.Type -ieq "A" } | Select-Object -First 1)
            
            # Establish the AD SearchBase from the Domain
            $SearchBase = ($Dom -replace "\.",", DC=")
            $SearchBase = "DC="+$SearchBase
        
            # Establish a CIM Session to Poll AD
            $Session = New-PSSession -ComputerName $GC.Name
        
            # Poll GC for Existing Users
            $ExistingUsers.AddRange((Invoke-Command -Session $Session -ScriptBlock { Get-ADUser -Filter * -SearchBase $Using:SearchBase }))
        }
        Write-Host Users found across all Global Catalogs: $ExistingUsers.Count
        
        [System.Collections.ArrayList]$ExistingFolders = @()
        foreach ($repo in $RedirectedFolderRoot)
        {
            $ExistingFolders.AddRange((Get-ChildItem $repo))
        }
        Write-Host Folders found across all Redirect Repos: $ExistingFolders.Count
    }

    PROCESS 
    {
        # Find the Orphaned Folders
        foreach ($User in $ExistingUsers.ToArray())
        {
            foreach($Folder in $ExistingFolders.ToArray())
            {
                if($User.samAccountName.ToLower() -eq $Folder.Name.ToLower())
                {
                    $ExistingUsers.Remove($User)
                    $ExistingFolders.Remove($Folder)
                }
            }
        }
        Write-Host Orphaned Redirected Folders found: $ExistingFolders.Count
    }

    END 
    {
        # Move the Orphaned Folders
        foreach($Folder in $ExistingFolders.ToArray())
        {
            if(!$Delete)
            {
                Move-Item -LiteralPath $Folder.FullName -Destination ($ArchiveRoot + "\" + $Folder.Name) -PassThru -Force
            }
            elseif($Delete)
            {
                Remove-Item -LiteralPath $Folder.FullName -Force
            }
        }
    }
}
Archive-RedirectedFolders -Domain <domain1>,[<domain2>,<domain3>,...] -RedirectedFolderRoot <root1>,[<root2,<root3>,...] -ArchiveRoot <archive dir root>
