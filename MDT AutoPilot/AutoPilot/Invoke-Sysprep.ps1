Param (
    $tsmanPID
)
Wait-Process $tsmanPID -ErrorAction SilentlyContinue

Start-Process "C:\Windows\System32\Sysprep\sysprep.exe" -ArgumentList "/oobe /quiet /reboot"