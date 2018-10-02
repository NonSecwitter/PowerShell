$ErrorActionPreference = "Stop"

try
{
# Variables

    $OldServer = ""
    $NewServer = ""

    # REGEX to update drivers
    $REGEX_HP_UNIV_PCL6 = "^(HP Universal Printing PCL 6)(.)+"
    $REPLACE_HP_UNIV_PCL6 = "HP Universal Printing PCL 6"

    $REGEX_HP_UNIV_PS = "^(HP Universal Printing PS)(.)+"
    $REPLACE_HP_UNIV_PS = "HP Universal Printing PS"

# Data Collection

    # Get list of old printers and ports
    $OldPrinters = Get-Printer -ComputerName $OldServer
    $OldPorts = Get-PrinterPort -ComputerName $OldServer

    # See what printers, drivers, and ports are available on the new server
    $NewPrinters = Get-Printer -ComputerName $NewServer
    $NewDrivers = Get-PrinterDriver -ComputerName $NewServer
    $NewPorts = Get-PrinterPort -ComputerName $NewServer

# Parsing
    
    # Deal with any driver changes
    $OldPrinters | ForEach-Object {$_.DriverName = $_.DriverName -replace $REGEX_HP_UNIV_PCL6,$REPLACE_HP_UNIV_PCL6}
    $OldPrinters | ForEach-Object {$_.DriverName = $_.DriverName -replace $REGEX_HP_UNIV_PS,$REPLACE_HP_UNIV_PS}

    # Focus only on TCP/IP printers
    $OldPorts = $OldPorts | Where-Object { $_.Description -like "*TCP/IP*" }

    # Limit our list of old printers to: standard printers, available drivers, not yet created, TCP/IP port
    $OldPrinters = $OldPrinters | Where-Object { $_.DeviceType -eq "Print" }
    $OldPrinters = $OldPrinters | Where-Object { $_.DriverName -in $NewDrivers.Name }
    $OldPrinters = $OldPrinters | Where-Object { $_.Name -notin $NewPrinters.Name }
    $OldPrinters = $OldPrinters | Where-Object { $_.PortName -in $OldPorts.Name }

    # Shrink the list of old ports to: needed for migration, don't already exist
    $OldPorts = $OldPorts | Where-Object { $_.Name -in $OldPrinters.PortName }


# Work

    # Replicate old ports to new server
    foreach ($OldPort in $OldPorts)
    {
        if ($OldPort.PrinterHostAddress -notin $NewPorts.PrinterHostAddress)
        {
            Add-PrinterPort -ComputerName $NewServer -Name $OldPort.PrinterHostAddress -PrinterHostAddress $OldPort.PrinterHostAddress
        }
    }

    # Create new printers
    foreach ($OldPrinter in $OldPrinters)
    {
        $OldPort = $OldPorts | Where-Object { $_.Name -eq $OldPrinter.PortName }
        Add-Printer -ComputerName $NewServer -Name $OldPrinter.Name -Shared -ShareName $OldPrinter.ShareName `
                    -DriverName $OldPrinter.DriverName -PortName $OldPort.PrinterHostAddress
    }

}
catch
{
    $Error[0]
    $Host.EnterNestedPrompt() 
}
