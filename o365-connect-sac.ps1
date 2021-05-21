param(                         
    [switch]$noprompt = $false,   ## if -noprompt used then user will not be asked for any input
    [switch]$noupdate = $false,   ## if -noupdate used then module will not be checked for more recent version
    [switch]$debug = $false       ## if -debug create a log file
)
<# CIAOPS
Script provided as is. Use at own risk. No guarantees or warranty provided.

Description - Log into the Office 365 Security and Compliance Center

Source - https://github.com/directorcia/Office365/blob/master/o365-connect-sac.ps1

Prerequisites = 1
1. Ensure msonline module installed or updated

More scripts available by joining http://www.ciaopspatron.com

#>

## Variables
$systemmessagecolor = "cyan"
$processmessagecolor = "green"
$errormessagecolor = "red"
$warningmessagecolor = "yellow"

## If you have running scripts that don't have a certificate, run this command once to disable that level of security
## set-executionpolicy -executionpolicy bypass -scope currentuser -force

Clear-Host
if ($debug) {
    write-host "Script activity logged at ..\o365-connect-sac.txt"
    start-transcript "..\o365-connect-sac.txt" | Out-Null                                        ## Log file created in parent directory that is overwritten on each run
}

write-host -foregroundcolor $systemmessagecolor "Microsoft 365 Security and Compliance Center Connection script started`n"
write-host -ForegroundColor $processmessagecolor "Prompt =",(-not $noprompt)

if (get-module -listavailable -name ExchangeOnlineManagement) {    ## Has the Exchange Online V2 PowerShell module been installed?
    write-host -ForegroundColor $processmessagecolor "Exchange Online V2 PowerShell module installed"
}
else {
    write-host -ForegroundColor $warningmessagecolor -backgroundcolor $errormessagecolor "[001] - Exchange Online V2 PowerShell module not installed`n"
    if (-not $noprompt) {
        do {
            $response = read-host -Prompt "`nDo you wish to install the Exchange Online V2 PowerShell module (Y/N)?"
        } until (-not [string]::isnullorempty($response))
        if ($result -eq 'Y' -or $result -eq 'y') {
            write-host -foregroundcolor $processmessagecolor "Installing PowerShellGet module - Administration escalation required"
            Start-Process powershell -Verb runAs -ArgumentList "Install-Module PowershellGet -Force" -wait -WindowStyle Hidden       
            write-host -foregroundcolor $processmessagecolor "Installing Exchange Online V2 PowerShell module - Administration escalation required"
            Start-Process powershell -Verb runAs -ArgumentList "install-Module -Name ExchangeOnlineManagement -Force -confirm:$false" -wait -WindowStyle Hidden
            write-host -foregroundcolor $processmessagecolor "Exchange Online V2 PowerShell module installed"
        }
        else {
            write-host -foregroundcolor $processmessagecolor "Terminating script"
            if ($debug) {
                Stop-Transcript | Out-Null                 ## Terminate transcription
            }
            exit 1                          ## Terminate script
        }
    }
    else {
        write-host -foregroundcolor $processmessagecolor "Installing PowerShellGet module - Administration escalation required"
        Start-Process powershell -Verb runAs -ArgumentList "Install-Module PowershellGet -Force" -wait -WindowStyle Hidden
        write-host -foregroundcolor $processmessagecolor "Installing Exchange Online V2 PowerShell module - Administration escalation required"
        Start-Process powershell -Verb runAs -ArgumentList "install-Module -Name ExchangeOnlineManagement -Force -confirm:$false" -wait -WindowStyle Hidden
        write-host -foregroundcolor $processmessagecolor "Exchange Online V2 PowerShell module installed"    
    }
}
if (-not $noupdate) {
    write-host -foregroundcolor $processmessagecolor "Check whether newer version of Exchange Online V2 PowerShell module is available"
    #get version of the module (selects the first if there are more versions installed)
    $version = (Get-InstalledModule -name ExchangeOnlineManagement) | Sort-Object Version -Descending  | Select-Object Version -First 1
    #get version of the module in psgallery
    $psgalleryversion = Find-Module -Name ExchangeOnlineManagement | Sort-Object Version -Descending | Select-Object Version -First 1
    #convert to string for comparison
    $stringver = $version | Select-Object @{n='ModuleVersion'; e={$_.Version -as [string]}}
    $a = $stringver | Select-Object Moduleversion -ExpandProperty Moduleversion
    #convert to string for comparison
    $onlinever = $psgalleryversion | Select-Object @{n='OnlineVersion'; e={$_.Version -as [string]}}
    $b = $onlinever | Select-Object OnlineVersion -ExpandProperty OnlineVersion
    #version compare
    if ([version]"$a" -ge [version]"$b") {
        Write-Host -foregroundcolor $processmessagecolor "Local module $a greater or equal to Gallery module $b"
        write-host -foregroundcolor $processmessagecolor "No update required"
    }
    else {
        Write-Host -foregroundcolor $warningmessagecolor "Local module $a lower version than Gallery module $b"
        write-host -foregroundcolor $warningmessagecolor "Update recommended"
        if (-not $noprompt) {
            do {
                $response = read-host -Prompt "`nDo you wish to update the Exchange Online V2 PowerShell module (Y/N)?"
            } until (-not [string]::isnullorempty($response))
            if ($result -eq 'Y' -or $result -eq 'y') {
                write-host -foregroundcolor $processmessagecolor "Updating Exchange Online V2 PowerShell module - Administration escalation required"
                Start-Process powershell -Verb runAs -ArgumentList "update-Module -Name ExchangeOnlineManagement -Force -confirm:$false" -wait -WindowStyle Hidden
                write-host -foregroundcolor $processmessagecolor "Exchange Online V2 PowerShell module - updated"
            }
            else {
                write-host -foregroundcolor $processmessagecolor "Exchange Online V2 PowerShell module - not updated"
            }
        }
        else {
        write-host -foregroundcolor $processmessagecolor "Updating Exchange Online V2 PowerShell module - Administration escalation required" 
        Start-Process powershell -Verb runAs -ArgumentList "update-Module -Name ExchangeOnlineManagement -Force -confirm:$false" -wait -WindowStyle Hidden
        write-host -foregroundcolor $processmessagecolor "Exchange Online V2 PowerShell module - updated"
        }
    }
}
write-host -foregroundcolor $processmessagecolor "Exchange Online V2 PowerShell module loading"

Try {
    Import-Module ExchangeOnlineManagement | Out-Null
}
catch {
    Write-Host -ForegroundColor $errormessagecolor "[002] - Unable to load Exchange Online V2 PowerShell module`n"
    Write-Host -ForegroundColor $errormessagecolor $_.Exception.Message
    if ($debug) {
        Stop-Transcript | Out-Null                ## Terminate transcription
    }
    exit 2
}
write-host -foregroundcolor $processmessagecolor "Exchange Online V2 PowerShell module loaded"

## Connect to Exchange Online service
write-host -foregroundcolor $processmessagecolor "Connecting to Security and Compliance Center"
try {
    $result = Connect-IPPSSession | Out-Null
}
catch {
    Write-Host -ForegroundColor $errormessagecolor "[003] - Unable to connect to Security and Compliance Center`n"
    Write-Host -ForegroundColor $errormessagecolor $_.Exception.Message
    if ($debug) {
        Stop-Transcript | Out-Null                 ## Terminate transcription
    }
    exit 3 
}

write-host -foregroundcolor $processmessagecolor "Connected to Security and Compliance Center`n"
write-host -foregroundcolor $systemmessagecolor "Microsoft 365 Security and Compliance Center Connection script finished`n"
if ($debug) {
    Stop-Transcript | Out-Null
}