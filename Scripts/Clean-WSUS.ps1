#Region VARIABLES

# WSUS Connection Parameters:
## Change settings below to your situation. ##
# FQDN of the WSUS server
[String]$parentServer = ""
# Use secure connection $True or $False
[Boolean]$useSecureConnection = $False
[Int32]$portNumber = 8530
# From address of email notification
#[String]$emailFromAddress = "noresponse@yourdomain.com"
# To address of email notification
#[String]$emailToAddress = "john.doe@yourdomain.com"
# Subject of email notification
#[String]$emailSubject = "WSUS Cleanup Results"
# Exchange server
#[String]$emailMailserver = "mailserver.yourdomain.local"


# Cleanup Parameters:
## Set to $True or $False ##
# Decline updates that have not been approved for 30 days or more, are not currently needed by any clients, and are superseded by an aproved update.
[Boolean]$supersededUpdates = $True
# Decline updates that aren't approved and have been expired my Microsoft.
[Boolean]$expiredUpdates = $True
# Delete updates that are expired and have not been approved for 30 days or more.
[Boolean]$obsoleteUpdates = $True
# Delete older update revisions that have not been approved for 30 days or more.
[Boolean]$compressUpdates = $True
# Delete computers that have not contacted the server in 30 days or more.
[Boolean]$obsoleteComputers = $True
# Delete update files that aren't needed by updates or downstream servers.
[Boolean]$unneededContentFiles = $True

#EndRegion VARIABLES

#Region SCRIPT

# Load .NET assembly
[void][reflection.assembly]::LoadWithPartialName("Microsoft.UpdateServices.Administration");

# Connect to WSUS Server
$wsusParent = [Microsoft.UpdateServices.Administration.AdminProxy]::getUpdateServer($parentServer,$useSecureConnection,$portNumber);

# Log the date first
$DateNow = Get-Date

# Perform Cleanup
$Body += "$parentServer ($DateNow ) :" | Out-String 
$CleanupManager = $wsusParent.GetCleanupManager();
$CleanupScope = New-Object Microsoft.UpdateServices.Administration.CleanupScope($supersededUpdates,$expiredUpdates,$obsoleteUpdates,$compressUpdates,$obsoleteComputers,$unneededContentFiles);
$Body += $CleanupManager.PerformCleanup($CleanupScope) | Out-String 

#Get list of downstream servers
$wsusDownstreams = [Microsoft.UpdateServices.Administration.AdminProxy]::DownstreamServerCollection;
$wsusDownstreams = $wsusParent.GetDownstreamServers();

#Clean each downstream server
$wsusDownstreams | ForEach-Object {
			$ping = New-Object System.Net.NetworkInformation.Ping
			$DSServer = $_.FullDomainName
			Try{
				$Reply = $ping.send($DSServer)
				$ReplyStatus = $Reply.Status
				Write-Host $ReplyStatus
			}
			catch{
				$ReplyStatus = "False"
				Write-Host $ReplyStatus
			}
			if ($ReplyStatus -eq "Success")
			{
				# Log the date first
				$DateNow = Get-Date
				$Body += $DSServer + " ($DateNow ) : " | Out-String
				$wsusReplica = [Microsoft.UpdateServices.Administration.AdminProxy]::getUpdateServer($_.FullDomainName,$useSecureConnection,$portNumber);
				$CleanupManager = $wsusReplica.GetCleanupManager();
				$CleanupScope = New-Object Microsoft.UpdateServices.Administration.CleanupScope($supersededUpdates,$expiredUpdates,$obsoleteUpdates,$compressUpdates,$obsoleteComputers,$unneededContentFiles);
				$Body += $CleanupManager.PerformCleanup($CleanupScope) | Out-String
			}else{
				# Log the date first
				$DateNow = Get-Date
				$Body += $DSServer + " ($DateNow ) : not pingable`n" | Out-String 
			}
}

# Send the results in an email
#Send-MailMessage -From $emailFromAddress -To $emailToAddress -Subject $emailSubject -Body $Body -SmtpServer $emailMailserver

#EndRegion SCRIPT
