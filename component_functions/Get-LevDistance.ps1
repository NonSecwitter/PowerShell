# FROM: https://www.codeproject.com/tips/102192/levenshtein-distance-in-windows-powershell #

[CmdletBinding()]
Param 
(
    [Parameter(Mandatory=$true,Position=0)]
    [AllowEmptyString()]
    [string]
    $FirstWord,

    [Parameter(Mandatory=$true,Position=1)]
    [AllowEmptyString()]
    [string]
    $SecondWord,

    [Parameter(Mandatory=$false,Position=2)]
    $CaseSensitive = $false
)

# Value to Return
$Distance = -1


# If either string is length = 0, the distance is
# the length of the other string
#
if ($FirstWord.Length -eq 0)
    { $Distance = $SecondWord.Length }

elseif ($SecondWord.Length -eq 0)
    { $Distance = $FirstWord.Length }


# Begin processsing if neither word is empty
if ($Distance -eq -1)
{

    if (!$CaseSensitive)
    {
        $FirstWord = $FirstWord.ToLowerInvariant()
        $SecondWord = $SecondWord.ToLowerInvariant()
    }

    # The Distance Grid stores data about the variation
    # between both words
    #
    $DistanceMatrix = New-Object -Type 'Int32[,]'`
                  -Arg ($FirstWord.Length+1),
                       ($SecondWord.Length+1)

    for ($i = 0; $i -le $FirstWord.Length; $i++)
        { $DistanceMatrix[$i,0] = $i }
    for ($j = 0; $j -le $SecondWord.Length; $j++)
        { $DistanceMatrix[0,$j] = $j }

    for($i = 1; $i -le $FirstWord.Length; $i++)
    {
        for($j = 1; $j -le $SecondWord.Length; $j++)
        {
            if($FirstWord[$i-1] -ceq $SecondWord[$j-1])
                { $cost = 0 }
            else
                { $cost = 1 }
            
            $GridAbove     = [int]$DistanceMatrix[($i-1),$j]
            $GridLeft      = [int]$DistanceMatrix[$i,($j-1)]
            $GridAboveLeft = [int]$DistanceMatrix[($i-1),($j-1)]
            
            $TempMin = [System.Math]::Min((1+$GridAbove),(1+$GridLeft))
            $DistanceMatrix[$i,$j] = [System.Math]::Min($TempMin, ($cost + $GridAboveLeft))
        }
    }

    $Distance = $DistanceMatrix[$FirstWord.Length,$SecondWord.Length]
}



Return $Distance
