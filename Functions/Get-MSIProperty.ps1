<#
    .AUTHOR
        Jonathon Anderson
    .COPYRIGHT 
        https://www.scconfigmgr.com/2014/08/22/how-to-get-msi-file-information-with-powershell/
    .SYNOPSIS
    .PARAMETER
    .EXAMPLE
    .TODO
#>

function Get-MSIProperty
{
    [CmdletBinding()]
    Param 
    (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [System.IO.FileInfo]$FilePath,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("ProductCode", "ProductVersion", "ProductName", "Manufaturer", "ProductLanguage", "FullVersion")]
        [String]$Property
    )

    BEGIN {}

    PROCESS 
    {
        $WindowsInstaller = New-Object -ComObject WindowsInstaller.Installer
        $MSIDatabase = $WindowsInstaller.GetType().InvokeMember("OpenDatabase", "InvokeMethod", $null, $WindowsInstaller, @($FilePath.FullName, 0))

        $Query = "SELECT Value FROM Property WHERE Property = '$($Property)'"

        $View = $MSIDatabase.GetType().InvokeMember("OpenView", "InvokeMethod", $null, $MSIDatabase, ($Query))
        $View.GetType().InvokeMember("Execute", "InvokeMethod", $null, $View, $null)


        $Record = $View.GetType().InvokeMember("Fetch", "InvokeMethod", $null, $View, $null)
        $Value = $Record.GetType().InvokeMember("StringData", "GetProperty", $null, $Record, 1)

        $MSIDatabase.GetType().InvokeMember("Commit", "InvokeMethod", $null, $MSIDatabase, $null)
        $view.GetType().InvokeMember("Close", "InvokeMethod", $null, $View, $null)
        $MSIDatabase = $null
        $View = $null

        return $Value

    }

    END 
    {
        [System.Runtime.InteropServices.Marshal]::ReleaseComObject($WindowsInstaller) | Out-Null
        [System.GC]::Collect()
    }
}

Get-MSIProperty
