<#
    .SYNOPSIS
         Checks free space on logical drives as % of free space remaining. 
         Sends E-Mail alert if free space is below specified threshold.    
         Be sure to specify e-mail related variables below.                
                                                                   
         Based on WMI Object Win32_LogicalDisk Class                       
         https://msdn.microsoft.com/en-us/library/aa394173(v=vs.85).aspx   
                                                                   
        Author and Copyright holder: Jonathon Anderson
    .PARAMETER
    .EXAMPLE                
#>

function Check-FreeDiskSpace
{

    [CmdletBinding()]
    Param
        (
        [Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
        [Alias("Name")]
        [string]
        $ComputerName = $env:COMPUTERNAME,

        [Parameter(Position=1)]
        [ValidateRange(1,100)]
        [int]
        $AlertBelowPercentFree = 5
        )
        begin{

    #
    # Variable for volume selection 
    #
    # This filtering may not work on non-windows systems.
    # Microsoft derived a Win32_LogicalDisk class from CIM_LogicalDisk.
    # Win32 version contains "DriveType" as below, but CIM does not.
    #
        
    # logical drive type in comma separated array 
    # (0) Unknown
    # (1) No Root Directory
    # (2) Removable Disk
    # (3) Local Disk
    # (4) Network Drive
    # (5) Compact Disk
    # (6) RAM Disk
    $DriveType   = (3)

    #
    # Variables for e-mail notification. 
    #
    # If your mail server requires TLS, specify port 587 (TLS) or 465 (less secure SSL)
    # otherwise, leave it blank.
    #
    # Note that if you use GMail, you need to "Enable Less Secure Apps" in your *ACCOUNT*
    # settings. This is in the settings under your picture, not your mailbox settings.
    #
    $mailFrom    = ""
    $mailTo      = ""
    $mailUser    = ""
    $mailPass    = ""
    $mailServer  = ""
    $mailPort    = ""
    $mailSubject = "Low Disk Space"
    $mailBody    = "One or more disks is low on space.`r`n`r`n" + "System: $ComputerName"


    ##########################################################################################
    ################# You shouldn't need to edit anything below here. ########################
    ##########################################################################################

    $securePass  = ConvertTo-SecureString $mailPass -AsPlainText -Force
    $cred        = New-Object System.Management.Automation.PSCredential($mailUser,$securePass)
    }

    process{
        foreach($computer in $ComputerName)
        {

            if(Test-Connection $ComputerName -Count 1 -ErrorAction SilentlyContinue)
            {
                $session = New-PSSession -ComputerName $ComputerName

                $volumes = Invoke-Command -Session $session -ScriptBlock { 

                                Get-WmiObject -Class Win32_LogicalDisk |
                                    Where-Object { $_.DriveType -eq 3} |
                                    Select-Object SystemName, DeviceID, VolumeName, Description, FileSystem,
                                    @{Name="PercentFree";Expression={[decimal]::Round(100*($_.FreeSpace/$_.Size),1)}}
                                }

                Remove-PSSession -Session $session

                $mailBody += $volumes | Out-String

                #if($volumes.PercentFree -lt $AlertBelowPercentFree)
                if($true)
                {
                    if ($mailPort -in (465,587))
                    {
                        #Send-MailMessage -Body $mailBody -Credential $cred -From $mailFrom -SmtpServer $mailServer -Subject $mailSubject -To $mailTo -Port $mailPort -UseSsl
                        Write-Host $mailBody
                    }
                    else
                    {
                        Write-Host $mailBody
                        #Send-MailMessage -Body $mailBody -Credential $cred -From $mailFrom -SmtpServer $mailServer -Subject $mailSubject -To $mailTo
                    }
                }
            }
        }
    }
    end{}
}

clear
