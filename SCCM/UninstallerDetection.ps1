[String]$LogfileName = ""
$UninstallerExe = ""


## End Variables

[String]$Logfile = "$env:Temp\$LogfileName.log"

Function Write-Log
{
    Param ([string]$logstring)
    If (Test-Path $Logfile)
    {
        If ((Get-Item $Logfile).Length -gt 2MB)
        {
            Rename-Item $Logfile $Logfile".bak" -Force
        }
    }
    $WriteLine = (Get-Date).ToString() + " " + $logstring
    Add-content $Logfile -value $WriteLine
}

$User = gwmi win32_computersystem -Property Username
$UserName = $User.UserName
$UserSplit = $User.UserName.Split("\")

# Parameter to Log
Write-Log "Start Script Execution"
Write-Log "Logged on User: $UserName"
Write-Log "Detection-String: $UninstallerExe"
If (Test-Path $UninstallerExe)
{
    Write-Log "Found DetectionFile"
    $UninstallerExe = Get-Item $UninstallerExe
    Write-Log "Get File Details"
    Write-Log "Version found: $($MSTeams.VersionInfo.FileVersion)"
    Write-Log "Script Exectuion End!"
    Write-Log ""
    Return $true
}
Else
{
    Write-Log "Warning: Uninstaller not found – need to install App!"
}
