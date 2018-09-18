$Actions =
(
    {00000000-0000-0000-0000-000000000001}, #Hardware Inventory
    {00000000-0000-0000-0000-000000000002}, #Software Inventory 
    {00000000-0000-0000-0000-000000000003}, #Discovery Inventory 
    {00000000-0000-0000-0000-000000000010}, #File Collection 
    #{00000000-0000-0000-0000-000000000011}, #IDMIF Collection 
    #{00000000-0000-0000-0000-000000000012}, #Client Machine Authentication 
    {00000000-0000-0000-0000-000000000021}, #Request Machine Assignments 
    {00000000-0000-0000-0000-000000000022}, #Evaluate Machine Policies 
    {00000000-0000-0000-0000-000000000023}, #Refresh Default MP Task 
    {00000000-0000-0000-0000-000000000024}, #LS (Location Service) Refresh Locations Task 
    {00000000-0000-0000-0000-000000000025}, #LS (Location Service) Timeout Refresh Task 
    {00000000-0000-0000-0000-000000000026}, #Policy Agent Request Assignment (User) 
    {00000000-0000-0000-0000-000000000027}, #Policy Agent Evaluate Assignment (User) 
    {00000000-0000-0000-0000-000000000031}, #Software Metering Generating Usage Report 
    {00000000-0000-0000-0000-000000000032}, #Source Update Message
    #{00000000-0000-0000-0000-000000000037}, #Clearing proxy settings cache 
    {00000000-0000-0000-0000-000000000040}, #Machine Policy Agent Cleanup 
    #{00000000-0000-0000-0000-000000000041}, #User Policy Agent Cleanup
    {00000000-0000-0000-0000-000000000042}, #Policy Agent Validate Machine Policy / Assignment 
    #{00000000-0000-0000-0000-000000000043}, #Policy Agent Validate User Policy / Assignment 
    {00000000-0000-0000-0000-000000000051}, #Retrying/Refreshing certificates in AD on MP 
    #{00000000-0000-0000-0000-000000000061}, #Peer DP Status reporting 
    #{00000000-0000-0000-0000-000000000062}, #Peer DP Pending package check schedule 
    #{00000000-0000-0000-0000-000000000063}, #SUM Updates install schedule 
    #{00000000-0000-0000-0000-000000000071}, #NAP action 
    #{00000000-0000-0000-0000-000000000101}, #Hardware Inventory Collection Cycle 
    #{00000000-0000-0000-0000-000000000102}, #Software Inventory Collection Cycle 
    #{00000000-0000-0000-0000-000000000103}, #Discovery Data Collection Cycle 
    #{00000000-0000-0000-0000-000000000104}, #File Collection Cycle 
    #{00000000-0000-0000-0000-000000000105}, #IDMIF Collection Cycle 
    #{00000000-0000-0000-0000-000000000106}, #Software Metering Usage Report Cycle 
    #{00000000-0000-0000-0000-000000000107}, #Windows Installer Source List Update Cycle 
    {00000000-0000-0000-0000-000000000108}, #Software Updates Assignments Evaluation Cycle 
    #{00000000-0000-0000-0000-000000000109}, #Branch Distribution Point Maintenance Task 
    #{00000000-0000-0000-0000-000000000110}, #DCM policy 
    {00000000-0000-0000-0000-000000000111}, #Send Unsent State Message 
    {00000000-0000-0000-0000-000000000112}, #State System policy cache cleanout 
    {00000000-0000-0000-0000-000000000113}, #Scan by Update Source 
    {00000000-0000-0000-0000-000000000114}, #Update Store Policy 
    #{00000000-0000-0000-0000-000000000115}, #State system policy bulk send high
    {00000000-0000-0000-0000-000000000116}, #State system policy bulk send low 
    {00000000-0000-0000-0000-000000000120}, #AMT Status Check Policy 
    {00000000-0000-0000-0000-000000000121}, #Application manager policy action 
    #{00000000-0000-0000-0000-000000000122}, #Application manager user policy action
    #{00000000-0000-0000-0000-000000000123}, #Application manager global evaluation action 
    {00000000-0000-0000-0000-000000000131}#, #Power management start summarizer
    #{00000000-0000-0000-0000-000000000221}, #Endpoint deployment reevaluate 
    #{00000000-0000-0000-0000-000000000222}, #Endpoint AM policy reevaluate 
    #{00000000-0000-0000-0000-000000000223}  #External event detection
)

$SmsClient = Get-CimClass SMS_Client -Namespace root/ccm
#$SessionProtocol = New-CimSessionOption -Protocol Dcom
#$Session = New-CimSession -ComputerName sjohnson-hp -SessionOption $SessionProtocol

foreach($action in $actions)
{
    $action

    #Invoke-CimMethod -CimClass $SmsClient -MethodName TriggerSchedule -Arguments @{sScheduleID = "{$action}"} # -CimSession $Session
    #Invoke-WmiMethod -Class SMS_Client -Namespace root/ccm -Name TriggerSchedule "{$action}"
}
