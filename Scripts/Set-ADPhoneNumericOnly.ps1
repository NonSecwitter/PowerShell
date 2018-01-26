<#
    .AUTHOR
        Jonathon Anderson
    .COPYRIGHT 
        Jonathon Anderson

    .SYNOPSIS
    .PARAMETER
    .EXAMPLE
    .TODO
		poll active directory for users with $SourceAttribute
		remove all non-numeric characters and leading 0's and 1's
		copy new value into target attribute
		update user with new attribute
#>

function Set-ADPhoneNumericOnly
{
    [CmdletBinding()]
    Param 
	(
		[Parameter(Mandatory=$True)]
		[string]$SourceAttribute,

		[Parameter(Mandatory=$True)]
		[string]$TargetAttribute,

		[Parameter(Mandatory=$True)]
		[string]$DomainController,

		[Parameter(Mandatory=$True)]
		[string]$SearchBase
	)

    BEGIN 
	{
        [System.Collections.ArrayList]$TargetUsers = @()
		$TargetUsers = Get-ADUser -Filter { (ObjectClass -eq 'User') -and ($SourceAttribute -like '*') } -SearchBase $SearchBase -Server $DomainController -Properties $SourceAttribute,$TargetAttribute
	}

    PROCESS 
	{
        [String]$PhoneNumber = $null
		foreach ($User in $TargetUsers)
		{
			$PhoneNumber = $User.$SourceAttribute
            $PhoneNumber = $PhoneNumber -replace "[^\d]",""
			$PhoneNumber = $PhoneNumber.TrimStart("0","1")

            if($PhoneNumber.Length -ne 10)
			{
				Set-ADUser -Server $DomainController -Identity $User.SamAccountName -Remove @{telephoneNumber=$User.$SourceAttribute}
				continue
			}

            Set-ADUser -Server $DomainController -Identity $User.SamAccountName -Add @{ipPhone="$PhoneNumber"}
		}
	}

    END {}
}
