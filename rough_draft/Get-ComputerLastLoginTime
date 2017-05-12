# Calculate the UTC time, in FileTime (Integer) format and convert it to a string
$LLTSlimit = (Get-Date).ToFileTimeUTC().ToString()

# Create the LDAP filter for the AD query
# Searching for ***enabled*** computer accounts which have lastLogonTimestamp
$LDAPFilter = "(&(objectCategory=Computer)(lastLogonTimestamp<=$LLTSlimit) (!(userAccountControl:1.2.840.113556.1.4.803:=2)))"

# Create an ADSI Searcher to query AD
$Searcher = new-object DirectoryServices.DirectorySearcher([ADSI]"")
$Searcher.filter = $LDAPFilter

# Execute the query
$Accounts = $Searcher.FindAll()

# Process the results
If ($Accounts.Count –gt 0)
{
	$Results = @() # Create an array to store all the results
	ForEach ($Account in $Accounts) # Loop through each account
	{ 
		$Result = "" | Select-Object Name,ADSPath,lastLogonTimestamp # Create an object to store this account in
		$Result.Name = [String]$Account.Properties.name # Add the name to the object as a string
		$Result.ADSPath = [String]$Account.Properties.adspath # Add the ADSPath to the object as a string
		$Result.lastLogonTimestamp = [DateTime]::FromFileTime([Int64]::Parse($Account.Properties.lastlogontimestamp)) # Add the lastLogonTimestamp to the object as a readable date
		$Results = $Results + $Result # Add this object to our array
	}
}

# Output the results
$Results | Format-Table -autosize
