<#
    .AUTHOR
        Jonathon Anderson
    .COPYRIGHT 
        Jonathon Anderson

    .SYNOPSIS
		Currently in beta form. This script is dependent on an external application to
		generate the HexString, such as MiTel's Option 125 helper. Further development
		will directly calculate the hex values from user input. (This may become a GUI
		app at some point.)
    .PARAMETER
    .EXAMPLE
    .TODO

#>

function Set-Option125
{
    [CmdletBinding(DefaultParameterSetName="Global")]
    Param 
	(
		[Parameter(Mandatory=$true)]
		[string]$HexString,

		[Parameter(ParameterSetName="Subnets",Mandatory=$true)]
		[IPAddress[]]$Subnets,

		[Parameter(ParameterSetName="Global", Mandatory=$true)]
		[switch]$Global
	)

    BEGIN 
	{
		
		# The pipe filters out $null values that powershell returns when splitting. *shrug*
		Write-Host "Splitting string into hex byte array."
		$EncapsulatedData = $HexString  -replace "(..)",'0x$1' -split "(0x..)" | Where-Object {$_}

		Import-Module DhcpServer

		Write-Host "Checking for Option 125 Definition."
		$Option125 = Get-DhcpServerv4OptionDefinition -OptionId 125 -ErrorAction SilentlyContinue

		if($Option125 -eq $null)
		{
			Write-Host "Option 125 does not exist, creating definition"
			Add-DhcpServerv4OptionDefinition -OptionId 125 -Type EncapsulatedData -Name "Vendor Option with Vendor ID" -Description "Provides Vendor Options with Explicit Vendor ID"
		}
		elseif ($Option125.Type -ne "EncapsulatedData")
		{
			Write-Host "Option 125 data type is incorrect. Recreating with data type EncapsulatedData"
			Get-DhcpServerv4OptionDefinition -OptionId 125 | Remove-DhcpServerv4OptionDefinition
			Add-DhcpServerv4OptionDefinition -OptionId 125 -Type EncapsulatedData -Name "Vendor Option with Vendor ID" -Description "Provides Vendor Options with Explicit Vendor ID"
		}
		else
		{
			Write-Host "Option 125 Definition exists."
		}

	}

    PROCESS 
	{
		
		if($PSCmdlet.ParameterSetName -eq "Global")
		{
            Write-Host "Checking for existing values set for Option 125 in Global Scope."
			$OptionValue125 = Get-DhcpServerv4OptionValue -OptionId 125 -ErrorAction SilentlyContinue
		
			if ($OptionValue125 -eq $null)
			{
				Write-Host "No value set for Option 125 at global level. Adding value."
				Set-DhcpServerv4OptionValue -OptionId 125 -Value $EncapsulatedData
			}
			else
			{
                [string]$ExistingString = $null
				$OptionValue125.Value | ForEach-Object {$ExistingString += $_} 
				$ExistingString = $ExistingString -replace "0x",""

                if($ExistingString -eq $HexString)
			    {
				    Write-Host "Existing global configuration matches provided hex data. Nothing to do."
			    }
			    else
			    {
				    while(($Confirmation -ne 'y') -and ($Confirmation -ne 'n'))
                    {
                        $Confirmation = Read-Host -Prompt "A configuration for Option 125 already exists in global scope. Do you want to overwrite the old value? (y/n)"
                        $Confirmation = $Confirmation.ToLower()

				        if($Confirmation.ToLower() -eq 'y')
				        {
					        Write-Host "Overwriting existing global configuration with new data."
				            Set-DhcpServerv4OptionValue -OptionId 125 -Value $EncapsulatedData
				        }
				        elseif($Confirmation.ToLower() -eq 'n')
				        {
					        Write-Host "Operation Cancelled"
				        }
                    }
			    }
			}	
		}
		elseif($PSCmdlet.ParameterSetName -eq "Subnets")
		{
			foreach ($Subnet in $Subnets)
			{
                Write-Host "Checking for existing values set for Option 125 in $Subnet."
				$OptionValue125 = Get-DhcpServerv4OptionValue -OptionId 125 -ScopeId $Subnet -ErrorAction SilentlyContinue
		
				if ($OptionValue125 -eq $null)
			    {
				    Write-Host "No value set for Option 125 in $Subnet. Adding value."
				    Set-DhcpServerv4OptionValue -OptionId 125 -Value $EncapsulatedData -ScopeId $Subnet
			    }
			    else
			    {
                    [string]$ExistingString = $null
				    $OptionValue125.Value | ForEach-Object {$ExistingString += $_} 
				    $ExistingString = $ExistingString -replace "0x",""

                    if($ExistingString -eq $HexString)
			        {
				        Write-Host "Existing configuration in $Subnet matches provided hex data. Nothing to do."
			        }
			        else
			        {
				        while(($Confirmation -ne 'y') -and ($Confirmation -ne 'n'))
                        {
                            $Confirmation = Read-Host -Prompt "A configuration for Option 125 already exists in $Subnet. Do you want to overwrite the old value? (y/n)"
                            $Confirmation = $Confirmation.ToLower()

				            if($Confirmation.ToLower() -eq 'y')
				            {
					            Write-Host "Overwriting existing configuration in $Subnet with new data."
				                Set-DhcpServerv4OptionValue -OptionId 125 -ScopeId $Subnet -Value $EncapsulatedData
				            }
				            elseif($Confirmation.ToLower() -eq 'n')
				            {
					            Write-Host "Operation Cancelled"
                    
				            }
                        }
			        }
			    }
			}
		}
	}

    END {}
}

