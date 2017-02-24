Function Swap-ArrayElements
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true, Position=0)]
        [ref]$Array,

        [Parameter(Mandatory=$true, Position=1)]
        $IndexOne,

        [Parameter(Mandatory=$true, Position=2)]
        $IndexTwo
    )

    $temp = $Array.Value[$IndexOne]
    $Array.Value[$IndexOne] = $Array.Value[$IndexTwo]
    $Array.Value[$IndexTwo] = $temp
}
