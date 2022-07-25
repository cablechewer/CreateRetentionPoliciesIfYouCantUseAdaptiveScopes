# Purpose
# Create rention policies for user mailboxes if Adaptive scopes are not available
#
# Unsupported script.  Use at your own risk.
#
# Creatopr: Chris Pollitt
# Created:  2022-07-25
# Last Modified:  2022-7-25


$BasePolicyName="Global 2 Year Retention"
#Connect to Exchange Online.  Comment this if you plan to connect independent of this script
connect-exchangeonline

#create array to store the list of mailboxes the policy will be built for 
[array]$Mbxs = @()

#retrieve the list of mailboxes.  Adjust filtering to suit.  Requires a version of PowerShell that supports get-exomailbox
[array]$Mbxs += get-exomailbox -ResultSize unlimited -properties customattribute6 -recipienttypedetails usermailbox | ?{$_.customattribute6 -eq "2"} | select userprincipalname 
write-host "returned " $Mbxs.count "mailboxes"

#Connect to Exchange Online.  Comment this if you plan to connect independent of this script
connect-ippssession
$lowerbound=0
$policynum=0

while($lowerbound -lt $Mbxs.count) {
  #Mailboxes are added in groups from lowerbound to upperbound.  Make sure lowerbound is less than the number of mailboxes
  
  $policyname=$BasePolicyName + ([string]$policynum).PadLeft(2,'0')  # sets the policy name and numbers it.  Padded with up to 2 zeroes
  if(($lowerbound + 999) -lt $Mbxs.count){
	# if there is room between the current lowerbound and the mailbox count grab the full block of 1000 mailboxes
    $upperbound = $lowerbound+999
  }
  else { #lowerbound is less than 1000 away from the total mailbox count, so set upperbound to the top of the mailbox count.
    $upperbound = $mbxs.count -1
  }
  write-host "Creating $policyname for mailboxes $lowerbound to $upperbound"
  $RuleName="Rule"+$policyname
  
  new-retentioncompliancepolicy -name $policyname -exchangelocation $mbxs[$lowerbound..$upperbound].userprincipalname #whatever other properties you want
  new-retentioncompliancerule -name $Rulename -policy $policyname -retentionduration 730 -retentioncomplianceaction Delete -ExpirationDateOption "CreationAgeInDays"
  $lowerbound+=999
  $policynum++
}

  