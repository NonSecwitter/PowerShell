# PowerShell has a hard time recursively calling a script if the path   #
# is formatted certain ways. Particularly, it does not handle network   #
# drives well (M: format masking \\ format) or running by double click  #
# (This prepends the ScriptPath with "&.\"                              #
 
# This simple script cleans up the ScriptPath so that a function can    #
# always be called recursively. This is particularly useful when you    #
# want a script to prompt for privilege elevation and call itself.      #

$ScriptPath = $myInvocation.InvocationName
$ScriptPath

if ($ScriptPath.StartsWith("&"))
{
    Write-Host 1
    $ScriptPath = ($myInvocation.Line).Split(" ")
    $ScriptPath = $ScriptPath[-1]
    $ScriptPath = $ScriptPath -replace "'",""
}
elseif ($ScriptPath.StartsWith("."))
{
    Write-Host 2
    $ScriptPath
    $ScriptPath = $ScriptPath.TrimStart(".")
    $ScriptPath = (Get-Location).Path + $ScriptPath
}
elseif ($ScriptPath -match ".:\\.*")
{
    Write-Host 3
    $Drives = Gwmi Win32_LogicalDisk -Filter "DriveType = 4"

    $ScriptRoot = $ScriptPath.Split("\")
    $ScriptRoot = $ScriptRoot[0]

    foreach ($drive in $drives)
    {
        if($drive.DeviceID -eq $ScriptRoot)
        {
            $ScriptPath = $ScriptPath.Replace($ScriptRoot, $drive.ProviderName)
        }
    }
}
