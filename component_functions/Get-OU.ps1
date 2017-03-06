Function Get-OU
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true,Position=0)]
        [Microsoft.ActiveDirectory.Management.ADAccount]
        $Acccount
    )

    Return ($Account.DistinguishedName -split 'CN=[^=]*,')
}
