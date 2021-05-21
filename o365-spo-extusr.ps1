<# CIAOPS
Script provided as is. Use at own risk. No guarantees or warranty provided.

Source - https://github.com/directorcia/Office365/blob/master/o365-spo-extusr.ps1

Description - Log into the show the external SharePoint Online users across all site collections

Prerequisites = 1
1. Ensure SharePoint online PowerShell module installed or updated

More scripts available by joining http://www.ciaopspatron.com

#>

## Variables
$systemmessagecolor = "cyan"
$processmessagecolor = "green"

## If you have running scripts that don't have a certificate, run this command once to disable that level of security
## set-executionpolicy -executionpolicy bypass -scope currentuser -force

Clear-Host

write-host -foregroundcolor $systemmessagecolor "Script started`n"

## Ensure that SharePoint Online modeule has been installed and loaded

Write-host -ForegroundColor $processmessagecolor "Getting all Sharepoint sites in tenant"
$SiteCollections  = Get-SPOSite -Limit All

foreach ($site in $SiteCollections) ## Loop through all Site Collections in tenant
{
    Write-host -ForegroundColor $processmessagecolor "Checking site:",$site.url

try {
    for ($i=0;;$i+=50) { ## There is a return limit of 50 users so need to capture data if more than 50 external users
        Get-SPOExternalUser -SiteUrl $site.Url -PageSize 50 -Position $i -ea Stop | Select-object DisplayName,EMail,AcceptedAs,WhenCreated,InvitedBy,@{Name = "Url" ; Expression = { $site.url }}
    }
}
catch { ## this is where any error handling will appear if required
}
}

write-host -foregroundcolor $systemmessagecolor "Script completed`n"
