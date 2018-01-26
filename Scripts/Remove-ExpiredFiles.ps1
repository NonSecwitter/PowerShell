function Remove-ExpiredFiles
{

    [CmdletBinding()]
    Param
    (
	    [Parameter(Mandatory=$true)]
	    [string]$Path,
	
	    [Parameter(Mandatory=$true)]
	    [int]$DaysUntilExpired=30,
	
	    [Parameter()]
	    [string[]]$Exclude,

        [Parameter()]
        [switch]$FilesOnly
    )



    $CurrentDateTime = Get-Date
    $CutoffDate = $CurrentDateTime.AddDays(-$DaysUntilExpired)

    if($FilesOnly)
    {
        $Files = Get-ChildItem $Path -Recurse -File -Exclude $Exclude | Where-Object { $_.LastWriteTime -le $CutoffDate }
    }
    else
    {
        $Files = Get-ChildItem $Path -Recurse -Exclude $Exclude | Where-Object { $_.LastWriteTime -le $CutoffDate }
    }

    $Files.Delete()
}