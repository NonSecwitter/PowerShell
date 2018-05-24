<#
    .AUTHOR
        Jonathon Anderson
    .SYNOPSIS
        Finds printers connected to $OldPrinter and attempts to create a
        connection to the same printer name on $NewPrinter. The printers
        *SHARE NAME* needs to be identical on each server.
    .PARAMETER
        $OldServer - Old server name in root of share path (\\this.is.the.server.name\this_is_the_printer)
        $NewServer - New server name in root of share path (\\server\printer)
    .EXAMPLE
        Remap-Printer -OldServer "old-print01" -NewServer "new-print02"
    .TODO
        -improve input validation
        -ability to specify new share name
#>

function Remap-Printer
{
    Param 
    (
    [Parameter(Mandatory=$true)]
    [String]$OldServer,
    
    [Parameter(Mandatory=$true)]
    [String]$NewServer
    )

    BEGIN 
    {

        $OldServer = $OldServer -replace "\\",""
        $NewServer = $NewServer -replace "\\",""

        # Test whether the $NewServer is online and accessible
        if(!(Test-Path \\$NewServer\print$)) {exit}
        
        # Collect Current Printers
        [System.Collections.ArrayList]$Printers = @()
        $Printers = Get-WmiObject -Query "SELECT * FROM Win32_Printer WHERE Network = 'TRUE'"
    }

    PROCESS
    {
        foreach($Printer in $Printers)
        {
            $NewPrinterPath = "\\"+$NewServer+"\"+$Printer.ShareName

            $ReturnValue = ([wmiclass]"Win32_Printer").AddPrinterConnection($NewPrinterPath).ReturnValue
        }
    }

    END 
    {
                
        # Old Printers
        [System.Collections.ArrayList]$Printers = @()
        $OldPrinters = Get-WmiObject -Query "SELECT * FROM Win32_Printer WHERE ServerName LIKE '%$OldServer%'"   
             
        # New Printers
        [System.Collections.ArrayList]$Printers = @()
        $NewPrinters = Get-WmiObject -Query "SELECT * FROM Win32_Printer WHERE ServerName LIKE '%$NewServer%'"

        foreach($OldPrinter in $OldPrinters)
        {
            foreach($NewPrinter in $NewPrinters)
            {
                if($NewPrinter.ShareName -eq $OldPrinter.ShareName)
                {
                    if($OldPrinter.Default -eq $true){$Return = $NewPrinter.SetDefaultPrinter()}
                    
                    $OldPrinter.Delete()
                }
            }
        }
    }
}
