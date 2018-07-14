$PowerShell = @(
    @{
        Name      = "Add Restart-Computer every night"
        Command   = "Unregister-ScheduledTask -TaskPath '\' -TaskName 'Nightly Reboot' -Confirm:`$false; Register-ScheduledTask -Action (New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument '-Command Restart-Computer -Force') -Trigger (New-ScheduledTaskTrigger -Daily -At 09:00pm) -User 'SYSTEM' -RunLevel Highest -Settings (New-ScheduledTaskSettingsSet -DontStopIfGoingOnBatteries -DontStopOnIdleEnd -WakeToRun) -TaskName 'Nightly Rebootv0.3' -Description 'v0.3' -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries"
        Detection = "[bool](Get-ScheduledTask -TaskName 'Nightly Rebootv0.3')"
    }
)
$PowerShell | ConvertTo-Json -Compress | Out-File "$PSScriptRoot\config.json" -Encoding default