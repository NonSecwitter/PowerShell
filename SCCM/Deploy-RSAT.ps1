# RSAT Install and Uninstall scripts for Win10 1809 or greater

##*===============================================
		##* INSTALLATION 
		##*===============================================
		[string]$installPhase = 'Installation'
		
		## <Perform Installation tasks here>
        
        # Capture Windows Update source configuration to restore later.
        $UseWSUS = Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "UseWUServer" | select -ExpandProperty UseWUServer

        # Configure Windows Update to use Microsoft as source
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "UseWUServer" -Value 0
        Restart-Service wuauserv

        # Install all RSAT Features
        $ErrorActionPreference = "Stop"
        try
        {
            $Capabilities = Get-WindowsCapability -Online -Name RSAT*
            foreach($capability in $capabilities)
            {
                $Result = Add-WindowsCapability -Online -Name $capability.Name
                $mainExitCode = 3010    
            }   
        }
        catch
        {
            $mainExitCode = -1;
        }
        $ErrorActionPreference = "Continue"

        # Restore Windows Update source configuration
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "UseWUServer" -Value $UseWSUS
        Restart-Service wuauserv
		
    
    ##*===============================================
		##* UNINSTALLATION
		##*===============================================
		[string]$installPhase = 'Uninstallation'
		
		# <Perform Uninstallation tasks here>
        
        # EasyRemove features can be uninstalled immediately.
        # The remaining RSAT features are a dependency for EasyRemove features.
        # They must be uninstalled after reboot
        $AllRsatCaps = Get-WindowsCapability -Online -Name "Rsat*" | Where-Object { $_.State -eq "Installed" }
        $ServerManager = $AllRsatCaps | Where-Object { $_.Name -like "Rsat.ServerManager.Tools*" }
        $SpecialRemoval = $AllRsatCaps | Where-Object { ($_.Name -like "Rsat.ActiveDirectory.DS-LDS.Tools*") -or ($_.Name -like "Rsat.FileServices.Tools*") -or ($_.Name -like "Rsat.GroupPolicy.Management.Tools*") }
        $EasyRemove = $AllRsatCaps | Where-Object { ($_.Name -notin $ServerManager.Name) -and ($_.Name -notin $SpecialRemoval.Name) }

        $ErrorActionPreference = "Stop"; 
        foreach($Capability in $EasyRemove)
        {
                
            try
            {
                Remove-WindowsCapability -Online -Name $Capability.Name
                $mainExitCode = 3010;
            }
            catch
            {
                Write-EventLog -LogName "SCCM_Custom" -Source "AppPackage_RSAT" -ErrorAction SilentlyContinue -EntryType Error -EventId 1337 -Message "Error removing $($Capability.Name)"
                continue
            }

        }        
        $ErrorActionPreference = "Continue"

# Command to be encoded starts here
        		
$Command = 
@'     
$ErrorActionPreference = "Stop"; 
try
{
    $AllRsatCaps = Get-WindowsCapability -Online -Name "Rsat*" | Where-Object { $_.State -eq "Installed" }
    $ServerManager = $AllRsatCaps | Where-Object { $_.Name -like "Rsat.ServerManager.Tools*" }
    $SpecialRemoval = $AllRsatCaps | Where-Object { ($_.Name -like "Rsat.ActiveDirectory.DS-LDS.Tools*") -or ($_.Name -like "Rsat.FileServices.Tools*") -or ($_.Name -like "Rsat.GroupPolicy.Management.Tools*") }

    if($AllRsatCaps -eq $null)
    {
        Get-ScheduledTask -TaskName "SCCM_RSAT_Removal" | Unregister-ScheduledTask -Confirm:$false
    }
    else 
    {
     
        # These need to be handled after easy removal is complete.
        foreach($Capability in $SpecialRemoval)
        {
            try
            {
                Remove-WindowsCapability -Online -Name $Capability.Name
                $mainExitCode = 3010;
            }
            catch
            {
                Write-EventLog -LogName "SCCM_Custom" -Source "AppPackage_RSAT" -ErrorAction SilentlyContinue -EntryType Error -EventId 1337 -Message "Error removing $($Capability.Name)"
                continue
            }
        }
        foreach($Capability in $ServerManager)
        {
            try
            {
                Remove-WindowsCapability -Online -Name $Capability.Name
                $mainExitCode = 3010;
            }
            catch
            {
                Write-EventLog -LogName "SCCM_Custom" -Source "AppPackage_RSAT" -ErrorAction SilentlyContinue -EntryType Error -EventId 1337 -Message "Error removing $($Capability.Name)"
                continue
            }
        }
    }
}
catch
{
    Write-EventLog -LogName "SCCM_Custom" -Source "AppPackage_RSAT" -ErrorAction SilentlyContinue -EntryType Error -EventId 1337 -Message "Error retrieving installed RSAT Features"
}
$ErrorActionPreference = "Continue"
'@     
# Command to be encoded ends here

        $EncodedCommand = [System.Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($Command))
        
        $TaskAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-Encoded $EncodedCommand"
        $TaskTrigger = New-ScheduledTaskTrigger -AtStartup
        $TaskPrincipal = New-ScheduledTaskPrincipal -UserId "NT AUTHORITY\System" -LogonType ServiceAccount -RunLevel Highest
        $TaskSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries:$true -DontStopIfGoingOnBatteries:$true -DisallowDemandStart:$false -WakeToRun:$true
        $Task = New-ScheduledTask -Action $TaskAction -Principal $TaskPrincipal -Settings $TaskSettings -Trigger $TaskTrigger
        Register-ScheduledTask -InputObject $Task -TaskName "SCCM_RSAT_Removal"
		
