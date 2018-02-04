$Apps = @(
    @{
        Name = "GIMP 2"
        Installer = "gimp-2.8.22-setup.exe"
        InstArgs = "/verysilent"
        Uninstaller = "C:\Program Files\GIMP 2\uninst\unins000.exe"
        UninstArgs = "/verysilent"
        appLocURL = "https://www.mirrorservice.org/sites/ftp.gimp.org/pub/gimp/v2.8/windows/gimp-2.8.22-setup.exe"
        wrkDir = "C:\Windows\Temp"
        detection = "C:\Program Files\GIMP 2\bin\gimp-2.8.exe"
        Mode = "Install"
    },
    @{
        Name = "VLC Media Player"
        Installer = "vlc-2.2.8-win32.exe"
        InstArgs = "/S"
        Uninstaller = "C:\Program Files (x86)\VideoLAN\VLC\uninstall.exe"
        UninstArgs = "/S"
        appLocURL = "http://vlc.viem-it.no/vlc/2.2.8/win32/vlc-2.2.8-win32.exe"
        wrkDir = "C:\Windows\Temp"
        detection = "C:\Program Files (x86)\VideoLAN\VLC\vlc.exe"
        Mode = "Install"
    }
    
)
$Apps | ConvertTo-Json -Compress | Out-File config.json