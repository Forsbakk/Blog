Param (
    $tsmanPID
)
#Wait for the task sequence to end
Wait-Process $tsmanPID -ErrorAction SilentlyContinue

#Run sysprep
Start-Process "C:\Windows\System32\Sysprep\sysprep.exe" -ArgumentList "/oobe /quiet /reboot"