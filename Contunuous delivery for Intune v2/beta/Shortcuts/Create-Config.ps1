$Shortcuts = @(
    @{
        Name            = "Google Earth"
        Type            = "lnk"
        Path            = "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"
        Arguments       = "https://earth.google.com/web"
        WorkingDir      = "C:\Program Files (x86)\Google\Chrome\Application"
        IconFileandType = "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe, 0"
        Description     = "Google Earth Cloud"
        Mode            = "Install"
    },
    @{
        Name            = "Office 365"
        Type            = "url"
        Path            = "https://portal.office.com"
        Arguments       = ""
        WorkingDir      = ""
        IconFileandType = "C:\Program Files (x86)\Microsoft Office\root\Office16\protocolhandler.exe, 0"
        Description     = "Office 365"
        Mode            = "Install"
    },
    @{
        Name            = "Word"
        Type            = "lnk"
        Path            = "C:\Program Files (x86)\Microsoft Office\root\Office16\winword.exe"
        WorkingDir      = "C:\Program Files (x86)\Microsoft Office\root\Office16\"
        IconFileandType = "C:\Program Files (x86)\Microsoft Office\root\Office16\winword.exe, 0"
        Description     = "Word"
        Mode            = "Install"
    },
    @{
        Name            = "Excel"
        Type            = "lnk"
        Path            = "C:\Program Files (x86)\Microsoft Office\root\Office16\excel.exe"
        WorkingDir      = "C:\Program Files (x86)\Microsoft Office\root\Office16\"
        IconFileandType = "C:\Program Files (x86)\Microsoft Office\root\Office16\excel.exe, 0"
        Description     = "Excel"
        Mode            = "Install"
    },
    @{
        Name            = "PowerPoint"
        Type            = "lnk"
        Path            = "C:\Program Files (x86)\Microsoft Office\root\Office16\powerpnt.exe"
        WorkingDir      = "C:\Program Files (x86)\Microsoft Office\root\Office16\"
        IconFileandType = "C:\Program Files (x86)\Microsoft Office\root\Office16\powerpnt.exe, 0"
        Description     = "PowerPoint"
        Mode            = "Install"
    }
)
$Shortcuts | ConvertTo-Json -Compress | Out-File "$PSScriptRoot\config.json" -Encoding default