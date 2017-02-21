Set-StrictMode -Version 2.0

# We can determine whether we have admin privileges. If so, we'll just keep running. # 
# If not, we'll prompt for elevated credentials and re-run the same script.          #
# Recursion's fun, ain't it??? :)                                                    #

$myWindowsID 		= [System.Security.Principal.WIndowsIdentity]::GetCurrent()
$myWindowsPrincipal	= New-Object System.Security.Principal.WindowsPrincipal($myWindowsID)
$adminRole			= [System.Security.Principal.WindowsBuiltInRole]::Administrator
if ($myWindowsPrincipal.IsInRole($adminRole))
{
	$Host.UI.RawUI.WindowTitle = "(Elevated)"+ $Host.UI.RawUI.WindowTitle
	Clear-Host
}
else
{
    # First, determine where Powershell thinks it is running the script from.  #
    #                                                                          #
    # PowerShell has a hard time recursively calling a script if the path      #
    # is formatted certain ways. Particularly, it does not handle network      #
    # drives well (M: format masking \\ format) or running by double click     #
    # (This prepends the ScriptPath with "&.\"                                 #

    $ScriptPath = $myInvocation.InvocationName

    if ($ScriptPath.StartsWith("&"))
    {
        $ScriptPath = ($myInvocation.Line).Split(" ")
        $ScriptPath = $ScriptPath[-1]
        $ScriptPath = $ScriptPath -replace "'",""
    }
    if ($ScriptPath.StartsWith("."))
    {
        $ScriptPath = $ScriptPath.TrimStart(".")
        $ScriptPath = (Get-Location).Path + $ScriptPath
    }
    if ($ScriptPath -match ".:\\.*")
    {
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

    $ScriptPath = $ScriptPath.ToString()

    $process = New-Object System.Diagnostics.Process
    $processStartInfo = New-Object System.Diagnostics.ProcessStartInfo "PowerShell"

    $processStartInfo.UseShellExecute = $true	
    $processStartInfo.Arguments = "-File $ScriptPath -ExecutionPolicy ByPass -NoExit -Sta"
	$processStartInfo.Verb = "runas"

    $process.StartInfo = $processStartInfo
    $null = $process.Start()
    if($process.HasExited)
    {
        $MyInvocation | select *
        Get-Location
    }

    #Exit
    #Return
}
