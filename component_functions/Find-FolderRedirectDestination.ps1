Function Find-FolderRedirectDestination
{

    Function Elevate-Privilege
    {
        # We can determine whether we have admin privileges. If so, we'll just keep running. # 
        # If not, we'll prompt for elevated credentials and re-run the same script.          #
        # Recursion's fun, ain't it??? :)                                                    #

        $myWindowsID 		= [System.Security.Principal.WIndowsIdentity]::GetCurrent()
        $myWindowsPrincipal	= New-Object System.Security.Principal.WindowsPrincipal($myWindowsID)
        $adminRole			= [System.Security.Principal.WindowsBuiltInRole]::Administrator

        if ($myWindowsPrincipal.IsInRole($adminRole))
        {
	        $Host.UI.RawUI.WindowTitle = "(Elevated)" + $myInvocation.ScriptName
	        Clear-Host
        }
        else
        {
            # First, determine where Powershell thinks it is running the script from.  #
            #                                                                          #
            # PowerShell has a hard time recursively calling a script if the path      #
            # is formatted certain ways. Particularly, it does not handle network      #
            # drives well (M: format masking \\ format) or running by double click     #
            # (This prepends the ScriptPath with "&.\"                                 #

            $ScriptPath = $myInvocation.InvocationName

            if ($ScriptPath.StartsWith("&"))
            {
                $ScriptPath = ($myInvocation.Line).Split(" ")
                $ScriptPath = $ScriptPath[-1]
                $ScriptPath = $ScriptPath -replace "'",""
            }
            if ($ScriptPath.StartsWith("."))
            {
                $ScriptPath = $ScriptPath.TrimStart(".")
                $ScriptPath = (Get-Location).Path + $ScriptPath
            }
            if ($ScriptPath -match ".:\\.*")
            {
                $Drives = Gwmi Win32_LogicalDisk -Filter "DriveType = 4"

                $ScriptRoot = $ScriptPath.Split("\")
                $ScriptRoot = $ScriptRoot[0]

                foreach ($drive in $drives)
                {
                    if($drive.DeviceID -eq $ScriptRoot)
                    {
                        $ScriptPath = $ScriptPath.Replace($ScriptRoot, $drive.ProviderName)
                    }
                }
            }

            $ScriptPath = $ScriptPath.ToString()

            $process = New-Object System.Diagnostics.Process
            $processStartInfo = New-Object System.Diagnostics.ProcessStartInfo "PowerShell"

            $processStartInfo.UseShellExecute = $true	
            $processStartInfo.Arguments = "-File $ScriptPath -ExecutionPolicy ByPass -NoExit -Sta"
	        $processStartInfo.Verb = "runas"

            $process.StartInfo = $processStartInfo
            $null = $process.Start()
            if($process.HasExited)
            {
                $MyInvocation | select *
                Get-Location
            }

            #Exit
            #Return
        }
    }

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

            $User = Get-ADUser $UserList.Value[$Selection].samAccountName

            Return $User
        }

        $FirstName = ($Name -split " ")[0]
        $LastName = ($Name -split " ")[1]

        [System.Collections.ArrayList] $UserList = 
            @(Get-UserList -FirstName $FirstName -LastName $LastName)

        $User     = Select-User ([ref]$UserList)

        Return $User
    }

    Function Get-OU
    {
        [CmdletBinding()]
        Param
        (
            [Parameter(Mandatory=$true,Position=0)]
            [Microsoft.ActiveDirectory.Management.ADAccount]
            $Account
        )

        Return ($Account.DistinguishedName -replace "^.*?,?(?=OU=)")
    }

    Function Get-GPOs
    {
        [CmdletBinding()]
        Param
        (
            [Parameter(Mandatory=$true,Position=0)]
            [Microsoft.ActiveDirectory.Management.ADAccount]
            $User
        )
        $OU = Get-OU $User
        $GPOs  = (Get-GPInheritance -Target $OU)

        [System.Collections.ArrayList] $guids = 
            $GPOs.InheritedGpoLinks.GpoId.Guid

        foreach($guid in $guids.ToArray())
        {
            [XML]$RSOP = Get-GPOReport -Guid $guid -ReportType XML
        
            [System.Collections.ArrayList]$paths +=
                     $RSOP.SelectNodes("//*[local-name()='DestinationPath']").InnerText
        }

        foreach($path in $paths.ToArray())
        {
            if(($path -eq $null) -OR ($path -eq ""))
            { 
                $paths.Remove($path)
            }
            elseif($path.ToString() -match "(%USERNAME%)")
            {
                $paths[$paths.IndexOf($path)] = $path -replace "%USERNAME%", $User.SamAccountName
            }
            else
            {
                $paths.Remove($path)
            }
        }
    
        Return $paths
    }

    Elevate-Privilege

    $User = Find-ADUser

    $OU = Get-OU $User

    $Destinations = Get-GPOs $User

    Return $Destinations
}

Find-FolderRedirectDestination
