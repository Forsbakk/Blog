$Shortcuts = @(
    @{
        Name = "GIMP 2"
        Type = "lnk"
        Path = "C:\Program Files\GIMP 2\bin\gimp-2.8.exe"
        WorkingDir = "%USERPROFILE%"
        IconFileandType = "C:\Program Files\GIMP 2\bin\gimp-2.8.exe, 0"
        Description = "GIMP 2.8"
        Mode = "Install"
    },
    @{
        Name = "Office 365"
        Type = "url"
        Path = "https://portal.office.com"
        Mode = "Install"
    },
    @{
        Name = "Google Earth"
        Type = "lnk"
        Path = "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"
        Arguments = "https://earth.google.com"
        WorkingDir = "C:\Program Files (x86)\Google\Chrome\Application"
        IconFileandType = "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe, 0"
        Description = "Google Earth Cloud"
        Mode = "Install"
    }
)
$Shortcuts | ConvertTo-Json -Compress | Out-File config.json