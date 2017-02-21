$fname = Read-Host -Prompt "Enter User's First Name"
$lname = Read-Host -Prompt "Enter User's Last Name"

$fname = $fname.Normalize()
$lname = $lname.Normalize()

$firstInitial = $fname[0] + "*"
$lastInitial  = $lname[0] + "*"

Get-ADUser -Filter { (GivenName -like $firstInitial) -and ( SurName -like $lastInitial) }
