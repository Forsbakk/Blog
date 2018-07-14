$Versions = @(
    @{
        Name    = "production"
        Version = "1.0.0"
        File    = "Script.prod.ps1"
    },
    @{
        Name    = "beta"
        Version = "1.0.0"
        File    = "Script.beta.ps1"
    }
)
$Versions | ConvertTo-Json -Compress | Out-File "$PSScriptRoot\config.json" -Encoding default