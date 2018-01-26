<#
.SYNOPSIS
Sets the "RunAs Administrator" flag on specified .LNK files.
.PARAMETER FileName
The .LNK file to modify
.PARAMETER RunAss
Boolean value to indicate whether .LNK should "RunAss Administrator"
.EXAMPLE
Set-ShortcutRunAsAdmin -FileName "C:\foo\bar.lnk" -RunAs $true
.EXAMPLE
Get-ChildItem -LiteralPath "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Administrative Tools" -Filter *.LNK | Set-ShortcutRunAsAdmin
#>

Function Set-ShortcutRunAsAdmin
{
    [CmdletBinding()]

    Param
    (
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        [String]
        $FileName,

        [Parameter(Mandatory=$false, Position=1)]
        [Bool]
        $RunAs = $true
    )
    BEGIN{}
    PROCESS
    {
        foreach($File in $FileName)
        {
            $bytes = [System.IO.File]::ReadAllBytes($FileName)
    
            if($RunAs)
            {
                $bytes[0x15] = $bytes[0x15] -bor 0x20
            }

            else
            {
                $bytes[0x15] = $bytes[0x15] -band 0xDF
            }

            [System.IO.File]::WriteAllBytes($FileName, $bytes)
        }
    }
    END{}

}
