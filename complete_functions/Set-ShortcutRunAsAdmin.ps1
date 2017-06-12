Function Set-ShortcutRunAsAdmin
{
    [CmdletBinding()]

    Param
    (
        [Parameter(Mandatory=$true, Position=0)]
        [String]
        $FileName,

        [Parameter(Mandatory=$true, Position=1)]
        [Bool]
        $RunAs
    )

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
