[CmdletBinding()]
Param
(
	[Parameter(Mandatory=$true)]
	[string]$Path,
	
	[Parameter(Mandatory=$true)]
	[int]$DaysUntilExpired=30,
	
	[Parameter(Mandatory=$false)]
	[string[]]$Exclude
)



$CurrentDateTime = Get-Date
$CutoffDate = $CurrentDateTime.AddDays(-$DaysUntilExpired)

$ObjectGroup = Get-ChildItem $Path -Recurse -Exclude $Exclude

foreach($Object in $ObjectGroup)
{
	if($Object.LastWriteTime -le $CutoffDate)
	{
		Remove-Item $Object
	}
}
