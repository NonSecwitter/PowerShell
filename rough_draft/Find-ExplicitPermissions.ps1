$OutFile = "C:\CorporatePermissions.txt"
$RootDir = "G:\"

$Directories = Get-ChildItem -LiteralPath $RootDir -Attributes Directory -Recurse

foreach($Directory in $Directories)
{
   $Directory | Where-Object { $_.GetAccessControl().Access.IsInherited -eq $false } | Select FullName | Out-File -Append $OutFile


   $Directory.GetAccessControl().Access | Where-Object { $_.IsInherited -eq $false } | 
       Select-Object @{Name="User/Group: "; Expression = {$_.IdentityReference}},FileSystemRights,AccessControlType |
        Out-File -Append $OutFile

}
