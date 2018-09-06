[String]$LogfileName = ""
[String]$UninstallerPath = ""
[String]$Logfile = "$env:Temp\$LogfileName.log"

## End Variables

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
Write-Log "---- Start Script Execution ----"
Write-Log "Logged on User: $env:USERNAME"
Write-Log "Search string: $UninstallerPath"



# Parameter to Log

If (Test-Path $UninstallerPath)
{
    [System.IO.FileSystemInfo]$UninstallerExe = Get-Item $UninstallerPath

    Write-Log "Found:  $UninstallerExe"
    Write-Log "Version: $($UninstallerExe.VersionInfo.FileVersion)"
    Write-Log "----END----"
    Return $true
}
Else
{
    Write-Log "Warning: Uninstaller not found – need to install App!"
    Write-Log "----END----"
}
