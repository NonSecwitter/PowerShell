###########################
##
## Created by NonSecwitter
##
###########################

<#
SYNOPSIS
Renames computers to serial.
 
DESCRIPTION
Depending on the make and model of a computer, the serial number can be stored in the bios and read from the WMI class WIN32_Bios using the SerialNumber property.
Leveraging this, it is easy to rename computer in a domain by polling Active Directory for a list and using the Rename-Computer cmdlet.

PARAMETER Credential
PS Credential for account with rights to change password.
 
PARAMETER SearchBase
Where to begin searching for computer objects. All subfolders will be searched. 
 
EXAMPLE
Rename-ADComputersToSerial -Credential (Get-Credential) -SearchBase 'OU=Computers,DC=Contoso,DC=COM'
 
INPUTS
None
 
OUTPUTS
None
 
NOTES
Make sure you don't rename your Domain Controller
 
LINK

#>
 
 
param(
    [Parameter(Mandatory=$true, HelpMessage="You must provide a credential. Try (Get-Credential)")]
    [System.Management.Automation.PSCredential] $Credential,
    [Parameter(Mandatory=$true, HelpMessage="You must provide a search base such as 'OU=Computers,DC=Contoso,DC=Com'")]
    [string] $SearchBase,
    [Parameter(Mandatory=$false, HelpMessage="Specify a location to store your log")]
    [string] $LogFile
    )

$Filter = 'ObjectClass -eq "computer"'

$TempComputerList = Get-ADObject -Filter $Filter -SearchBase $SearchBase
$ComputerList = New-Object System.Collections.ArrayList

foreach($Computer in $TempComputerList)
{
    $ComputerList.Add($Computer)
}


foreach($Computer in $ComputerList.ToArray())
{
	$ComputerName = $Computer.Name
	$IsOnline = Test-Connection -ComputerName $ComputerName -Quiet
    
    if(!$IsOnline)
    {
        $ComputerList.Remove($Computer)
        continue
    }

	$SerialNumber = (Get-WMIobject -ComputerName $ComputerName -Class Win32_BIOS -Property SerialNumber).SerialNumber
		
	if($SerialNumber -eq $ComputerName)
	{
        $ComputerList.Remove($Computer)
        continue
    }
		
    Rename-Computer -ComputerName $ComputerName -Force -NewName $SerialNumber -DomainCredential $Credential
}

if($LogFile -ne $null)
{
    $Log = New-Item -ItemType File -Name $LogFile
    ("Computers renamed on " + (Get-Date)) > $Log
    $ComputerList >> $Log
}
