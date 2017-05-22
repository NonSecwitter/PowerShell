#Searches WSUS for the KB articles published by Microsoft to address the leaked NSA tools.
#Will look for highest superseding update, and report status of that.

clear
function Get-SupersedingUpdate
{
    Param(
    [Parameter(Mandatory=$true)]
    [Microsoft.UpdateServices.Administration.IUpdate]$update
    )
    $highest = $update

    $higherUpdates = $null
    $higherUpdates = $update.GetRelatedUpdates([Microsoft.UpdateServices.Administration.UpdateRelationship]::UpdatesThatSupersedeThisUpdate)

    foreach($higher in $higherUpdates)
    {
        if($higher.IsSuperseded)
        {
            $highest = Get-SupersedingUpdate $higher
        }
        else
        {
            $highest = $higher
        }
    }
    return $highest
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
$wsus = Get-WsusServer
[Microsoft.UpdateServices.Administration.UpdateCollection]$NSAPatches = New-Object Microsoft.UpdateServices.Administration.UpdateCollection

Write-Host "Compiling a list of Updates`r`nThis takes a while"
foreach($kb in $allKB)
{
   $updatescope.TextIncludes = $kb
   $kbUpdates = $wsus.GetUpdates($updatescope)

   foreach ($update in $kbUpdates)
   {
      $update = Get-SupersedingUpdate $update

      try
      {
        $NSAPatches.Add($update) > $null
      }
      catch{}
   }
}
clear
   foreach ($patch in $NSAPatches)
   {
    $ComputerGroupStatus = $patch.GetSummaryPerComputerTargetGroup($true)
    $patch | Select-Object ProductTitles,LegacyName,IsApproved,IsDeclined,State | sort LegacyName | Format-Table
    $ComputerGroupStatus | Select-Object UnknownCount,NotApplicableCount,NotInstalledCount,DownloadedCount,InstalledCount,InstalledPendingRebootCount,FailedCount | Format-Table
    pause
   }
