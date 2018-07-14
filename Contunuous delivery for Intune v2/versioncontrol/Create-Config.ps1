$Versions = @(
    @{
        Name    = "production"
        Version = "1.0.0"
    },
    @{
        Name    = "beta"
        Version = "1.0.0"
    }
)
$Versions | ConvertTo-Json -Compress | Out-File "$PSScriptRoot\config.json" -Encoding default