$regfiles = @(
    @{
        URL = ""
        detection = "[bool]((Get-ItemPropertyValue -Path `"HKLM:\Software\Policies\Microsoft\OneDrive`" -Name SilentAccountConfig) -eq 1)"
        Type = "HKLM"
    },
    @{
        URL = ""
        detection = "[bool]((Get-ItemPropertyValue -Path REGISTRY::HKEY_USERS\.DEFAULT\Software\Microsoft\Office\16.0\Common\General -Name ShownFileFmtPrompt) -eq 1)"
        Type = "HKCU"
    }
)
$regfiles | ConvertTo-Json -Compress | Out-File "$PSScriptRoot\config.json" -Encoding default