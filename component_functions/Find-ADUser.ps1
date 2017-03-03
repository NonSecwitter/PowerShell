[CmdletBinding()]
Param
(
    [Parameter(Mandatory=$True)]
    $FirstName,

    [Parameter(Mandatory=$False)]
    $LastName = ""
)

Function Get-LevDistance 
{
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

    $Distance = -1

    if ($FirstWord.Length -eq 0)
        { $Distance = $SecondWord.Length }

    elseif ($SecondWord.Length -eq 0)
        { $Distance = $FirstWord.Length }

    if ($Distance -eq -1)
    {

        if (!$CaseSensitive)
        {
            $FirstWord = $FirstWord.ToLowerInvariant()
            $SecondWord = $SecondWord.ToLowerInvariant()
        }

        # The Distance Grid stores data about variation
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
}

Function Get-UserList
{
    [CmdletBinding()]
    Param
    (
        [string]
        $GivenName,

        [string]
        $SurName
    )

    Return Get-ADUser -Filter * | Select-Object *, @{N='LevDistance'; E={""}}
}

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

Function Append-LevDistance
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true, Position=2)]
        [Object] 
        [ref]$Users,

        [Parameter(Mandatory=$true, Position=0)]
        [String]
        $FirstName,

        [Parameter(Mandatory=$true, Position=1)]
        [Object]
        $LastName
    )
    $SearchName = $FirstName + $LastName

    foreach ($User in $Users.ToArray())
    {
        if (($FirstName -eq "") -OR ($LastName -eq ""))
        {                                                                                  
            $distance1 = Get-LevDistance $SearchName $User.GivenName     
            $distance2 = Get-LevDistance $SearchName $User.SurName
        }                                                            
        else                                                         
        {                                                            
            $ADName1 = $Users[$i].GivenName + $Users[$i].Surname     
            $ADName2 = $Users[$i].SurName + $Users[$i].Givenname     
            $distance1 = Get-LevDistance $ADName1 $SearchName        
            $distance2 = Get-LevDistance $ADName2 $SearchName                                                                              
        } 

        if ($distance1 -gt ($SearchName.Length/2)-AND $distance2 -gt ($SearchName.Length/2))
        { 
            $Users.Remove($User)
        }
        else
        {
            if($distance1 -le $distance2) { $Users[$Users.IndexOf($User)].LevDistance = $distance1 }
            else { $Users[$Users.IndexOf($User)].LevDistance = $distance2 }  
        }
    }
}

Function Order-UserList
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true,Position=0)]
        [ref]$Users
    )
    for ($i=0; $i -lt $Users.Value.Count-1; $i++)
    {
        for($j = $i+1; $j -lt $Users.Value.Count; $j++)
        {
            if ($Users.Value[$j].LevDistance -lt $Users.Value[$i].LevDistance) 
            {
                Swap-ArrayElements ([ref]$Users.Value) $j $i 
            }
        }
    }
} 

Function Find-ADUser
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$True)]
        $FirstName,

        [Parameter(Mandatory=$False)]
        $LastName
    )

    [System.Collections.ArrayList]$Users = Get-UserList -GivenName $FirstName -SurName $LastName

    Append-LevDistance -Users ([ref]$Users) $FirstName $LastName
    Order-UserList ([ref]$Users)

    Write-Host
    foreach ($User in $Users)
    {
        Write-Host ([array]::IndexOf($Users, $User)+1):: $User.Name
    }
    Write-Host

    $Selection  = Read-Host "Select User"
    $Selection -= 1
    
    Return $Users[$Selection]
}


Find-ADUser -FirstName $FirstName -LastName $LastName
