#Searches WSUS for the KB articles published by Microsoft to address the leaked NSA tools.
#Will look for highest superseding update, and report status of that.

clear
function Get-SupersedingUpdate
{
    Param
    (
        [Parameter(Mandatory=$true, Position=0)]
        [Microsoft.UpdateServices.Administration.IUpdate]$update
    )
    
    $null = .{
    [Microsoft.UpdateServices.Administration.UpdateCollection] $superUpdates = New-Object Microsoft.UpdateServices.Administration.UpdateCollection
    

    if (!$update.IsSuperseded)
    {
        $superUpdates.Add($update)
    }
    else
    {
        $superUpdates.AddRange( $update.GetRelatedUpdates([Microsoft.UpdateServices.Administration.UpdateRelationship]::UpdatesThatSupersedeThisUpdate))
        [Microsoft.UpdateServices.Administration.UpdateCollection] $temp = New-Object Microsoft.UpdateServices.Administration.UpdateCollection
        $temp = $superUpdates
        
        foreach($super in $temp)
        {
            $superUpdates.AddRange((Get-SupersedingUpdate $super))
            $superUpdates.Remove($super)
        }
    }
    
    }
    return $superUpdates
}


$allKB = @(4012598
 ,4012212
 ,4012213
 ,4012214
 ,4012215
 ,4012216
 ,4012217
 ,4012606
 ,4013198
 ,4013429
 ,4012598
 ,2347290
 ,4012215
 ,4012216
 ,4012217
 ,4012598
 ,4012606
 ,4013198
 ,4013429	
 ,3011780	
 ,975517
 ,958644  )

$updatescope = New-Object Microsoft.UpdateServices.Administration.UpdateScope
$computerScope = New-Object Microsoft.UpdateServices.Administration.ComputerTargetScope

$wsus = Get-WsusServer
[Microsoft.UpdateServices.Administration.UpdateCollection]$NSAPatches = New-Object Microsoft.UpdateServices.Administration.UpdateCollection

Write-Host "Compiling a list of Updates`r`nThis takes a while because superseding udpates branch over time"
foreach($kb in $allKB)
{
   $updatescope.TextIncludes = $kb
   $kbUpdates = $wsus.GetUpdates($updatescope)

   foreach ($update in $kbUpdates)
   {
    try
    {
      $NSAPatches.AddRange((Get-SupersedingUpdate $update))
    }
    catch [System.Management.Automation.MethodInvocationException]
    {
     #Write-Host $_
    }
   }
}

clear
   foreach ($patch in $NSAPatches)
   {
    $kbNum = $patch.KnowledgeBaseArticles
    Write-Host "`r`n"--------- KB$kbnum ---------


    $ComputerGroupStatus = $patch.GetSummaryPerComputerTargetGroup($true)

    $patch | Select-Object LegacyName,IsApproved,IsDeclined,State,
            @{Name="SupersedesOthers";Expression={$_.HasSupersededUpdates}},
            IsSuperseded | Format-Table
 
    $ComputerGroupStatus |
                     Select-Object @{Name="Group";Expression=`
                     {($wsus.GetComputerTargetGroup($_.ComputerTargetGroupId)).Name}},
                     UnknownCount,NotApplicableCount,NotInstalledCount,FailedCount |
                     Format-Table
                     

    $ComputerGroupStatus |
                     Select-Object @{Name="Group";Expression=`
                     {($wsus.GetComputerTargetGroup($_.ComputerTargetGroupId)).Name}},
                     DownloadedCount,InstalledCount,InstalledPendingRebootCount |
                     #Format-Table
    pause
   }
   
