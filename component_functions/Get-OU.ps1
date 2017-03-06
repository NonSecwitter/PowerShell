Function Get-OU
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true,Position=0)]
        [Microsoft.ActiveDirectory.Management.ADAccount]
        $Account
    )

    Return ($Account.DistinguishedName -split 'CN=[^=]*,')
}
