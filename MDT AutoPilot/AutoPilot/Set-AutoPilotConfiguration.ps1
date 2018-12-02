#Copy the AutoPilot JSON
New-Item -Path "$env:SystemRoot\Provisioning\AutoPilot" -ItemType Directory
Copy-Item -Path "$PSScriptRoot\AutoPilotConfigurationFile.JSON" -Destination "$env:SystemRoot\Provisioning\AutoPilot\AutoPilotConfigurationFile.JSON"

#Get PID of TsManager
$tsMan = Get-Process -Name "TsManager"

#Start sysprep script
Start-Process "powershell.exe" -ArgumentList "-File `"$PSScriptRoot\Invoke-Sysprep.ps1`" -tsmanPID $($tsMan.Id)"