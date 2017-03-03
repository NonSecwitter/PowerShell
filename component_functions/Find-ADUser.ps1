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

    $firstInitial = $GivenName[0] + "*"
    $lastInitial  = $SurName[0] + "*"

    return (Get-ADUser -Filter { ((GivenName -like $firstInitial) -and ( SurName -like $lastInitial)) -OR
           ((GivenName -like $lastInitial) -and ( SurName -like $firstInitial)) })
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

Function Order-UserList
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true, Position=2)]
        [Object] 
        $Users,

        [Parameter(Mandatory=$true, Position=0)]
        [String]
        $FirstName,

        [Parameter(Mandatory=$true, Position=1)]
        [Object]
        $LastName
    )
    $Distances = @(0)*$Users.Length
    $SearchName = $FirstName + $LastName

    for($i = 0; $i -lt $Users.Length; $i++)
    {
        if (($FirstName -eq "") -OR ($LastName -eq ""))              
        {                                                            
            $ADName1 = $Users[$i].GivenName                          
            $ADName2 = $Users[$i].SurName                            
            $distance1 = Get-LevDistance $ADName1 $SearchName        
            $distance2 = Get-LevDistance $ADName2 $SearchName        
                                                                     
            if($distance1 -le $distance2) { $distance = $distance1 } 
            else { $distance = $distance2 }                          
        }                                                            
        else                                                         
        {                                                            
            $ADName1 = $Users[$i].GivenName + $Users[$i].Surname     
            $ADName2 = $Users[$i].SurName + $Users[$i].Givenname     
            $distance1 = Get-LevDistance $ADName1 $SearchName        
            $distance2 = Get-LevDistance $ADName2 $SearchName        
                                                                     
            if($distance1 -le $distance2) { $distance = $distance1 } 
            else { $distance = $distance2 }                          
        }                                                            

        $Distances[$i] = $distance
    }

    for ($i=0; $i -lt $Distances.Length-1; $i++)
    {
        for($j = $i+1; $j -lt $Distances.Length; $j++)
        {
            if ($Distances[$j] -lt $Distances[$i]) 
            {             
                Swap-ArrayElements ([ref]$Distances) $j $i
                Swap-ArrayElements ([ref]$Users) $j $i

                
            }
        }
    }
    Return $Users
} 

Function Find-ADUser
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$True)]
        $FirstName,

        [Parameter(Mandatory=$False)]
        $LastName = ""
    )

    $Users = Get-UserList -GivenName $FirstName -SurName $LastName
    $Users = Order-UserList -Users $Users $FirstName $LastName

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
