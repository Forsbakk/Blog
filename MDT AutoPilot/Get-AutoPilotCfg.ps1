#Run block by block

#Install WindowsAutoPilot module
Install-Module WindowsAutoPilotIntune

#Connect to AutoPilot
Connect-AutoPilotIntune

#Get all AutoPilot profiles and convert to JSON
Get-AutoPilotProfile | ConvertTo-AutoPilotConfigurationJSON