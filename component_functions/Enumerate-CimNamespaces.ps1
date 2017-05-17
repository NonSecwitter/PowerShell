function Enumerate-CIMNamespaces
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$false, Position=0)]
        $CurrentNameSpace = "root"
    )

    $Children = Get-CimInstance -Namespace $CurrentNameSpace -ClassName "__NameSpace"
    $NameSpaces = $null

    foreach($name in $Children)
    {
        $NameSpaces += @($CurrentNameSpace + "/" + $name.Name)
        $NameSpaces += Enumerate-CIMNamespaces ($CurrentNameSpace + "/" + $name.Name)
        
    }

    return $NameSpaces
}

Enumerate-CIMNamespaces
