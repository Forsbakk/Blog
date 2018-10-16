$ChocoPkgs = @(
    @{
        Name = "googlechrome"
        Mode = "install"
    },
    @{
        Name = "sccmtoolkit"
        Mode = "install"
    },
    @{
        Name = "microsoft-teams.install"
        Mode = "install"
    },
    @{
        Name = "git"
        Mode = "install"
    }, 
    @{
        Name = "vscode"
        Mode = "install"
    },
    @{
        Name = "spotify"
        Mode = "install"
    }
)
$ChocoPkgs | ConvertTo-Json -Compress | Out-File "$PSScriptRoot\config.json" -Encoding default