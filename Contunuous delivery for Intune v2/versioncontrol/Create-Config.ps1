$Versions = @(
    @{
        Name    = "production"
        Version = "1.0.4"
    },
    @{
        Name    = "beta"
        Version = "1.0.4"
    }
)
$Versions | ConvertTo-Json -Compress | Out-File "$PSScriptRoot\config.json" -Encoding default