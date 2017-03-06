Function Find-ADUser
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$True, Position=0)]
        [AllowEmptyString()]
        $Name
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
            [ref]$UserList,

            [Parameter(Mandatory=$true, Position=0)]
            [AllowEmptyString()]
            [String]
            $FirstName,

            [Parameter(Mandatory=$true, Position=1)]
            [AllowEmptyString()]
            [String]
            $LastName
        )

        Function Set-Distance ([int]$distance1, [int]$distance2)
                                                            {
        if ($distance1 -gt ($SearchName.Length/2)-AND $distance2 -gt ($SearchName.Length/2))
        { 
            $UserList.Remove($User)
        }
        elseif($distance1 -le $distance2)
        { 
            $UserList[$UserList.IndexOf($User)].LevDistance = $distance1
        }
        else 
        {
            $UserList[$UserList.IndexOf($User)].LevDistance = $distance2
        }
    }

        $SearchName = $FirstName + $LastName

        if (($FirstName -eq "") -OR ($LastName -eq ""))
        { 
            foreach ($User in $UserList.ToArray())
            {                                                                                 
                $distance1 = Get-LevDistance $SearchName $User.GivenName     
                $distance2 = Get-LevDistance $SearchName $User.SurName

                Set-Distance $distance1 $distance2
            }
        }                                                            
        else                                                         
        {
            foreach ($User in $UserList.ToArray())
            {                                                            
                $ADName1 = $User.GivenName + $User.Surname     
                $ADName2 = $User.SurName   + $User.Givenname     
                $distance1 = Get-LevDistance $ADName1 $SearchName        
                $distance2 = Get-LevDistance $ADName2 $SearchName

                Set-Distance $distance1 $distance2
            }                                                                           
        } 
    }

    Function Order-UserList
    {
        [CmdletBinding()]
        Param
        (
            [Parameter(Mandatory=$true,Position=0)]
            [ref]$UserList
        )
        for ($i=0; $i -lt $UserList.Value.Count-1; $i++)
        {
            for($j = $i+1; $j -lt $UserList.Value.Count; $j++)
            {
                if ($UserList.Value[$j].LevDistance -lt $UserList.Value[$i].LevDistance) 
                {
                    Swap-ArrayElements ([ref]$UserList.Value) $j $i 
                }
            }
        }
    } 

    Function Get-UserList
    {
        [CmdletBinding()]
        Param
        (
            [Parameter(Mandatory=$True)]
            [AllowEmptyString()]
            [String]
            $FirstName,

            [Parameter(Mandatory=$False)]
            [AllowEmptyString()]
            [String]
            $LastName
        )

        [System.Collections.ArrayList]$UserList = Get-ADUser -Filter * | Select-Object *, @{N='LevDistance'; E={""}}

        Append-LevDistance -UserList ([ref]$UserList) -FirstName $FirstName -LastName $LastName
        Order-UserList     -UserList ([ref]$UserList)

        Return $UserList
    }

    Function Select-User
    {
        [CmdletBinding()]
        Param
        (
            [Parameter(Mandatory=$True,Position=0)]
            [ref]$UserList
        )
    
        Write-Host
        foreach ($User in $UserList.Value)
        {
            Write-Host ([array]::IndexOf($UserList.Value, $User)+1):: $User.Name
        }
        Write-Host

        $Selection  = (Read-Host "Select User") - 1
        Return $UserList.Value[$Selection]
    }

    $FirstName = ($Name -split " ")[0]
    $LastName = ($Name -split " ")[1]

    $UserList = Get-UserList -FirstName $FirstName -LastName $LastName
    $User     = Select-User ([ref]$UserList)

    Return $User
}


Find-ADUser

