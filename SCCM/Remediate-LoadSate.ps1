$cmd = @"
?\Path\To\loadstate.exe 
"@

$args = @"
"@

$ComputerName = ""

if ($Session -eq $null)
{
    $Session = New-PSSession -ComputerName $ComputerName
}

Invoke-Command -Session $Session -ScriptBlock { Start-Job -ScriptBlock { Start-Process -FilePath $using:cmd -ArgumentList $using:args } }

Sleep 10
Invoke-Command -Session $Session -ScriptBlock { Get-Job  }
