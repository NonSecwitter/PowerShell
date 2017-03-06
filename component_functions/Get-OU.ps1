Function Get-OU
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true,Position=0)]
        [Microsoft.ActiveDirectory.Management.ADAccount]
        $User
    )

    Return ($User.DistinguishedName -split 'CN=[^=]*,')
}
