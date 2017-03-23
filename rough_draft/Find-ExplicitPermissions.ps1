$OutFile = "C:\CorporatePermissions.txt"
$RootDir = "G:\"

$Directories = Get-ChildItem -LiteralPath $RootDir -Attributes Directory -Recurse

foreach($Directory in $Directories)
{
    If(($Directory.GetAccessControl().Access | Where-Object { $_.IsInherited -eq $false }).Count -gt 0)
    {
        $Directory.FullName | Out-File -Append $OutFile
    }

    $Directory.GetAccessControl().Access | Where-Object { $_.IsInherited -eq $false } | 
        Select-Object @{Name="User/Group: "; Expression = {$_.IdentityReference}},FileSystemRights,AccessControlType |
        Out-File -Append $OutFile
}
