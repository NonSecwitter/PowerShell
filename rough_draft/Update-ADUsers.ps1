$CSVList = ""

[System.Collections.Arraylist]$Content = Get-Content $CSVList
[System.Collections.Arraylist]$errorUser =  New-Object System.Collections.ArrayList

foreach($line in $Content.ToArray())
{    
    $line = $line -replace """"
    [System.Collections.Arraylist] $elements = $line -split ",\s*"
    
    $lastName = $elements[0]
    $firstName = (($elements[1]).Split(" "))[0]
    $title = $elements[2]
    $location = $elements[3]
    $department = $elements[4]
    $phone = $elements[5]

    $lastName
    $firstName
    $title
    $location
    $department
    $phone
    
    $username = $firstName.Substring(0,1) + $lastName

    try
    {
        $ADuser = Get-ADUser $username -Properties *

        if (![String]::IsNullOrEmpty($ADuser.Title))
        {
            Set-ADUser -Identity $username -Remove  @{Title=$ADuser.Title}
        }

        if (![String]::IsNullOrEmpty($ADuser.Office))
        {
        Set-ADUser -Identity $username -Remove  @{physicalDeliveryOfficeName = $ADUser.Office}
        }

        if (![String]::IsNullOrEmpty($ADuser.Department))
        {
        Set-ADUser -Identity $username -Remove  @{Department = $ADuser.Department}
        }
        
        if (![String]::IsNullOrEmpty($ADuser.OfficePhone))
        {
        Set-ADUser -Identity $username -Remove  @{telephoneNumber = $ADuser.OfficePhone}
        }
        
        if (![String]::IsNullOrEmpty($ADuser.Company))
        {
        Set-ADUser -Identity $username -Remove  @{Company = $ADuser.Company}
        }



        if (![String]::IsNullOrEmpty($Title))
        {
        Set-ADUser -Identity $username -Replace @{Title=$Title}
        }

        if (![String]::IsNullOrEmpty($location))
        {
        Set-ADUser -Identity $username -Replace @{physicalDeliveryOfficeName = $location}
        }
        
        if (![String]::IsNullOrEmpty($department))
        {
        Set-ADUser -Identity $username -Replace @{Department = $department}
        }
        
        if (![String]::IsNullOrEmpty($phone))
        {
        Set-ADUser -Identity $username -Replace @{telephoneNumber = $phone}
        }
        
        Set-ADUser -Identity $username -Replace @{Company = ""}
        
    }
    catch
    {
        $errorUser.Add($lastname + ", " + $firstName)
        Pause
    }
    Write-Host "------------------------------------"  
}

$errorUser | sort
