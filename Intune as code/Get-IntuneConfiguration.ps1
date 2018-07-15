$User = "jonas@M365EDU402934.OnMicrosoft.com" #Change this to your username

function Get-AuthToken { #Function for fetching authToken
    Param(
        $User = $null
    )
    if ($User -eq $null -or $User -eq "") {
        $User = Read-Host "Username for Intune authentication"
    }
    $userUpn = New-Object "System.Net.Mail.MailAddress" -ArgumentList $User
    $tenant = $userUpn.Host

    $AadModule = Get-Module -Name "AzureAD" -ListAvailable
    If ($AadModule -eq $null) {
        $AadModule = Get-Module -Name "AzureADPreview" -ListAvailable
    }

    if ($AadModule -eq $null) {
        Write-Host "AAD module not installed" -ForegroundColor Red
        Exit
    }

    if ($AadModule.count -gt 1) {
        $Latest_Version = ($AadModule | Select-Object version | Sort-Object)[-1]
        $aadModule = $AadModule | Where-Object { $_.version -eq $Latest_Version.version }

        if ($AadModule.count -gt 1) {
            $aadModule = $AadModule | Select-Object -Unique
        }
        $adal = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
        $adalforms = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.Platform.dll"
    }
    else {
        $adal = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
        $adalforms = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.Platform.dll"
    }

    [System.Reflection.Assembly]::LoadFrom($adal) | Out-Null
    [System.Reflection.Assembly]::LoadFrom($adalforms) | Out-Null

    $adal = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
    $adalforms = Join-Path $AadModule.ModuleBase "Microsoft.IdentityModel.Clients.ActiveDirectory.Platform.dll"

    $clientId = "d1ddf0e4-d672-4dae-b554-9d5bdfd93547"
    $redirectUri = "urn:ietf:wg:oauth:2.0:oob"
    $resourceAppIdURI = "https://graph.microsoft.com"
    $authority = "https://login.microsoftonline.com/$Tenant"

    $authContext = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext" -ArgumentList $authority
    $platformParameters = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.PlatformParameters" -ArgumentList "Auto"
    $userId = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.UserIdentifier" -ArgumentList ($User, "OptionalDisplayableId")
    $authResult = $authContext.AcquireTokenAsync($resourceAppIdURI, $clientId, $redirectUri, $platformParameters, $userId).Result

    if ($authResult.AccessToken) {
        $authHeader = @{
            'Content-Type'  = 'application/json'
            'Authorization' = "Bearer " + $authResult.AccessToken
            'ExpiresOn'     = $authResult.ExpiresOn
        }
        return $authHeader
    }
}

#Checking authToken, fetches if not exists or has expired
if ($global:authToken) {
    $DateTime = (Get-Date).ToUniversalTime()
    $TokenExpires = ($authToken.ExpiresOn.datetime - $DateTime).Minutes

    if ($TokenExpires -le 0) {
        $global:authToken = Get-AuthToken -User $User
    }
}
else {
    $global:authToken = Get-AuthToken -User $User
}

#Get the profile named as $devRestricrionName and output it as $devRestricrionFile
$devRestricrionName = "Custom Device Restrictions" #Name of the configuration we are getting
$devRestricrionFile = "CDR.json" #Name of the file we outputs
(Invoke-RestMethod "https://graph.microsoft.com/Beta/deviceManagement/deviceConfigurations" -Method Get -Headers $authToken -ContentType "application/json").value | Where-Object { $_.displayName -eq $devRestricrionName } | ConvertTo-Json -Compress | Out-File "$PSScriptRoot\$devRestricrionFile"


$devRestricrionName = "Custom Windows Update Ring"
$devRestricrionFile = "CWUR.json"
(Invoke-RestMethod "https://graph.microsoft.com/Beta/deviceManagement/deviceConfigurations" -Method Get -Headers $authToken -ContentType "application/json").value | Where-Object { $_.displayName -eq $devRestricrionName } | ConvertTo-Json -Compress | Out-File "$PSScriptRoot\$devRestricrionFile"

#Get the Office 365 deployment and output it as $AppFile
$AppName = "Office 365" #Name of App in Intune
$AppFile = "O365.json"
(Invoke-RestMethod "https://graph.microsoft.com/Beta/deviceAppManagement/mobileApps" -Method Get -Headers $authToken -ContentType "application/json").value | Where-Object { $_.displayName -eq $AppName } | ConvertTo-Json -Compress | Out-File "$PSScriptRoot\$AppFile"