$Versions = @(
    @{
        Name    = "production"
        Version = "1.0.3"
    },
    @{
        Name    = "beta"
        Version = "1.0.3"
    }
)
$Versions | ConvertTo-Json -Compress | Out-File "$PSScriptRoot\config.json" -Encoding default