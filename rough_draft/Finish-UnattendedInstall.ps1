# First, determine where Powershell thinks it is running the script from. #

$ScriptPath = $myInvocation.InvocationName

# If the location is a mapped drive, Powershell will not be able to run it #
# with the M:\ syntax, so we need to find the UNC, strip the drive letter, #
# and append the UNC.                                                      #

if (!$ScriptPath.StartsWith("\\"))
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

# Now that we have a script path in a format that is recognizable to Powershell,     #
# we can determine whether we have admin privileges. If so, we'll just keep running. # 
# If not, we'll prompt for elevated credentials and re-run the same script.          #
# Recursion's fun, ain't it??? :)                                                    #

$myWindowsID 		= [System.Security.Principal.WIndowsIdentity]::GetCurrent()
$myWindowsPrincipal	= New-Object System.Security.Principal.WindowsPrincipal($myWindowsID)
$adminRole			= [System.Security.Principal.WindowsBuiltInRole]::Administrator
if ($myWindowsPrincipal.IsInRole($adminRole))
{
	$Host.UI.RawUI.WindowTitle = $myInvocation.MyCommand.Definition + "(Elevated)"
	Clear-Host
}
else
{
	$newProcess = New-Object System.Diagnostics.ProcessStartInfo "PowerShell"
    $newProcess.Arguments = "-ExecutionPolicy ByPass -File $ScriptPath -NoExit"
	$newProcess.Verb = "runas"
	[System.Diagnostics.Process]::Start($newProcess)
    #Exit
    Return
}

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

#Start-Transcript -Path "C:\Transcript.txt" -Append -Force -IncludeInvocationHeader -NoClobber

###############################
########## Functions ##########
###############################


function Set-ComputerName
{ $null = .{
	$ComputerName   = $env:ComputerName
	$SerialNumber   = (Get-WMIobject -ComputerName $ComputerName -Class Win32_BIOS -Property SerialNumber).SerialNumber
	$SerialNumber   = $SerialNumber.Substring(0, [math]::min($SerialNumber.Length,14))

	if($SerialNumber -ne $ComputerName)
	{
		Set-AutoLogonCount
		Rename-Computer -ComputerName $ComputerName -NewName $SerialNumber -Force -Restart
	}
  }
	return $SerialNumber -eq $ComputerName
}

###############################

function Create-DomainCredential
{ $null = .{
	$UserName   = ""
	$Password   = "" | ConvertTo-SecureString -AsPlainText -Force 
	$Credential = New-Object System.Management.Automation.PSCredential($UserName, $Password)
 }
 return $Credential
}

###############################

function Join-Domain
{ $null = .{
	$DomainJoined = (Get-WmiObject -Class Win32_ComputerSystem).PartOfDomain

	if (!$DomainJoined)
	{	
		$Domain     = ""

		$UserName   = ""
		$Password   = ""
		
		$DomainJoin = 1
		$CreateAccount = 2
		$AllowJoinIfAlreadyJoined = 32
		
		$OU	= ""
		
		$Computer = Get-WMIObject Win32_ComputerSystem
		
		$Ret = $Computer.JoinDomainOrWorkGroup($Domain, $Password, $UserName, $OU, $DomainJoin + $CreateAccount + $AllowJoinIfAlreadyJoined)
		$Ret = $Ret.ReturnValue
		
		Switch($Ret)
		{
			2224
			{
				$Ret = $Computer.JoinDomainOrWorkGroup($domain, $Password, $UserName, $OU, $DomainJoin + $AllowJoinIfAlreadyJoined)
				$Ret = $Ret.ReturnValue
			}
		}

		Restart-Computer -Force		
	}
  }
	return $DomainJoined
}

###############################

function Change-OU
{$null = .{

 }
}

###############################

function Set-AutoLogonCount
{
	param ([int]$Count = 1)
	
	$WinLogonKey	= Get-Item "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\WinLogon"
	
	Set-ItemProperty -Path $WinLogonKey.PSPath -Name AutoLogonCount -Value $Count
}

###############################

function Set-AutoAdminLogon
{
	param ([bool]$Enabled = $true)
	
	$WinLogonKey	= Get-Item "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\WinLogon"
	
	if($Enabled)
	{
		[int]$Value = 1
	}
	else
	{
		[int]$Value = 0
	}
	
	Set-ItemProperty -Path $WinLogonKey.PSPath -Name AutoAdminLogon -Value $Value
}

###############################

function Install-PSWindowsUpdate
{ $null = .{
	Get-PackageProvider -Name NuGet -ForceBootStrap

	$UpdateModule    = Get-Module -ListAvailable -Name PSWindowsUpdate

	if($UpdateModule -eq $null)
	{
		Save-Module -Name PSWindowsUpdate -Path "C:\Windows\System32\WindowsPowerShell\v1.0\Modules\" -Force

		Install-Module -Name PSWindowsUpdate -Force
	}
	
	$UpdateModule    = Get-Module -ListAvailable -Name PSWindowsUpdate
  }		
	return !($UpdateModule -eq $null)
}

###############################

function Process-WindowsUpdates
{ $null = .{
	Import-Module PSWindowsUpdate
	
	do	
	{
		wuauclt.exe /reportnow
		Start-Sleep -s 30
		wuauclt.exe /reportnow /detectnow
		Start-Sleep -s 30
		
		$RebootNeeded   = Get-WURebootStatus -Silent
		$PendingUpdates = (Get-WUList).count -gt 0
		
		if($RebootNeeded)
		{
			Restart-Computer -Force
		}
		elseif($PendingUpdates)
		{
			Get-WUInstall -AcceptAll -IgnoreReboot
			
			wuauclt.exe /reportnow
			Start-Sleep -s 30
			wuauclt.exe /reportnow /detectnow
			Start-Sleep -s 30
			
			Restart-Computer -Force
		}
	} while ($RebootNeeded -or $PendingUpdates)
	
  }
	return !($RebootNeeded -or $PendingUpdates)
}

###############################

function Set-AdditionalRun
{
	param ([bool]$RunAgain = $true)
	
	$ScriptPath 		= "C:\Finish-UnattendedInstall.ps1"
	$ExecutionString 	= "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy ByPass -Command `"& $ScriptPath`""

	$RunOncePath 		= "HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce"
		
	if($RunAgain)
	{
		New-Item -Path $RunOncePath -ErrorAction SilentlyContinue
		New-ItemProperty -Path $RunOncePath -Name Finish-UnattendedInstall -Value $ExecutionString -ErrorAction SilentlyContinue
	}
	else
	{
		Remove-ItemProperty -Path $RunOncePath -Name Finish-UnattendedInstall
	}
}

###############################

function Remove-DriveLetter
{ 
	param ([string]$Label = "system")
	
	$Volume				= Get-Volume -FileSystemLabel $Label
	$DriveLetter		= $Volume.DriveLetter
	
	if ($DriveLetter -ne $null)
	{
		$DriveLetter		= $Volume.DriveLetter
		$AccessPath			= ($DriveLetter + ":\")
		$Partition			= Get-Partition -DriveLetter $DriveLetter
		$PartitionNumber	= $Partition.PartitionNumber
		$DiskNumber 		= $Partition.DiskNumber

	
		Remove-PartitionAccessPath -DiskNumber $DiskNumber -PartitionNumber $PartitionNumber -AccessPath $AccessPath
	}

}

###############################
######## End Functions ########
###############################
rundll32.exe user32.dll,LockWorkStation
Set-AutoLogonCount
Set-AutoAdminLogon
Set-AdditionalRun

$ComputerNameSet = Set-ComputerName

if($ComputerNameSet)
{
	$DomainSet = Join-Domain
}

if($DomainSet)
{
	$PSWindowsUpdateReady = Install-PSWindowsUpdate
}

if($PSWindowsUpdateReady)
{
	Set-AutoLogonCount -Count 4
	$UpdatesFinished = Process-WindowsUpdates
}

if($UpdatesFinished)
{
	Remove-Item -LiteralPath C:\Windows\Panther\Unattend.xml -Force
	Remove-Item -LiteralPath C:\Finish-UnattendedInstall.ps1 -Force
	Remove-DriveLetter -Label "system"
	
	Set-AdditionalRun  -RunAgain $False
	Set-AutoLogonCount -Count 0
	Set-AutoAdminLogon -Enabled $false
	Restart-Computer -Force
}
