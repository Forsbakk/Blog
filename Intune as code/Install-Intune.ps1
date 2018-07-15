$User = "jonas@m365edu402934.onmicrosoft.com" #Change this to your username
$JSONFilesToInstall = Get-ChildItem $PSScriptRoot | Where-Object { $_.Extension -eq ".json" } #Location of JSONS
$UserGroup = "All Users" #User group to deploy production material
$BetaUserGroup = "Beta Users" #User group to create & deploy beta material
$CDPath = "$PSScriptRoot\CD4Intune" #Temporary path for CD-files
$CDForIntuneProd = "https://raw.githubusercontent.com/Forsbakk/Blog/master/Contunuous%20delivery%20for%20Intune%20v2/Install/Install-CDforIntune/Install-CDforIntune.production.ps1"
$CDForIntuneBeta = "https://raw.githubusercontent.com/Forsbakk/Blog/master/Contunuous%20delivery%20for%20Intune%20v2/Install/Install-CDforIntune/Install-CDforIntune.beta.ps1"

function Get-AuthToken {
    #Function for fetching authToken
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

#Clean up crap that comes with a demo tennant
try {
    $uri = "https://graph.microsoft.com/Beta/deviceManagement/deviceConfigurations"
    $Configurations = (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value
}

catch {
    $ex = $_.Exception
    $errorResponse = $ex.Response.GetResponseStream()
    $reader = New-Object System.IO.StreamReader($errorResponse)
    $reader.BaseStream.Position = 0
    $reader.DiscardBufferedData()
    $responseBody = $reader.ReadToEnd();
    Write-Host "Response content:`n$responseBody" -f Red
    Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
}
ForEach ($cfg in $Configurations) {
    try {
        $uri = "https://graph.microsoft.com/Beta/deviceManagement/deviceConfigurations/$($cfg.id)"
        Invoke-RestMethod -Uri $uri -Headers $authToken -Method Delete
    }

    catch {
        $ex = $_.Exception
        $errorResponse = $ex.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($errorResponse)
        $reader.BaseStream.Position = 0
        $reader.DiscardBufferedData()
        $responseBody = $reader.ReadToEnd();
        Write-Host "Response content:`n$responseBody" -f Red
        Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
    }
}

#Create $BetaUserGroup
$properties = @{
    "displayName"     = $BetaUserGroup
    "mailEnabled"     = $false
    "mailNickname"    = "nomail"
    "securityEnabled" = $true
}
$JSON = $properties | ConvertTo-Json -Compress

try {
    $uri = "https://graph.microsoft.com/beta/groups"
    $BetaAADGroup = Invoke-RestMethod -Uri $uri -Body $JSON -Headers $authToken -Method Post
}

catch {
    $ex = $_.Exception
    $errorResponse = $ex.Response.GetResponseStream()
    $reader = New-Object System.IO.StreamReader($errorResponse)
    $reader.BaseStream.Position = 0
    $reader.DiscardBufferedData()
    $responseBody = $reader.ReadToEnd();
    Write-Host "Response content:`n$responseBody" -f Red
    Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
}

#Get $UserGroup
try {
    $AADUserGroup = (Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/groups?`$filter=displayname eq '$UserGroup'" –Headers $authToken –Method Get).Value
}

catch {
    $ex = $_.Exception
    $errorResponse = $ex.Response.GetResponseStream()
    $reader = New-Object System.IO.StreamReader($errorResponse)
    $reader.BaseStream.Position = 0
    $reader.DiscardBufferedData()
    $responseBody = $reader.ReadToEnd();
    Write-Host "Response content:`n$responseBody" -f Red
    Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
}

#Get all JSON-files and assigns them to $UserGroup
foreach ($file in $JSONFilesToInstall) {
    $content = Get-Content $file.FullName | ConvertFrom-Json
    #Gets Device configurations
    if ($content.'@odata.type' -eq "#microsoft.graph.windows10GeneralConfiguration" -or $content.'@odata.type' -eq "#microsoft.graph.windowsUpdateForBusinessConfiguration") {

        $JSON = $content | Select-Object -Property * -ExcludeProperty "id", "createdDateTime", "lastModifiedDateTime" | ConvertTo-Json

        #Adding device configuration
        try {
            $uri = "https://graph.microsoft.com/Beta/deviceManagement/deviceConfigurations"
            $devRes = Invoke-RestMethod -Uri $uri -Headers $authToken -Method Post -Body $JSON -ContentType "application/json"
        }
        catch {
            $ex = $_.Exception
            $errorResponse = $ex.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($errorResponse)
            $reader.BaseStream.Position = 0
            $reader.DiscardBufferedData()
            $responseBody = $reader.ReadToEnd();
            Write-Host "Response content:`n$responseBody" -f Red
            Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
        }

        $properties = @{
            "deviceConfigurationGroupAssignments" = @(
                @{
                    "@odata.type" = "#microsoft.graph.deviceConfigurationGroupAssignment"
                    "targetGroupId" = $AADUserGroup.id
                }
            )
        }
        $JSON = $properties | ConvertTo-Json -Depth 3 -Compress

        #Assigns device configuration to $UserGroup
        try {
            $uri = "https://graph.microsoft.com/Beta/deviceManagement/deviceConfigurations/$($devRes.id)/assign"
            Invoke-RestMethod -Uri $uri -Headers $authToken -Method Post -Body $JSON -ContentType "application/json"
        }
        catch {
            $ex = $_.Exception
            $errorResponse = $ex.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($errorResponse)
            $reader.BaseStream.Position = 0
            $reader.DiscardBufferedData()
            $responseBody = $reader.ReadToEnd();
            Write-Host "Response content:`n$responseBody" -f Red
            Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
        }
    }
    #Gets Office 365 deployment
    elseif ($content.'@odata.type' -eq "#microsoft.graph.officeSuiteApp") {

        $JSON = $content | Select-Object -Property * -ExcludeProperty "id", "uploadstate", "publishingState", "createdDateTime", "lastModifiedDateTime" | ConvertTo-Json

        #Creates the Office 365 app
        try {
            $uri = "https://graph.microsoft.com/Beta/deviceAppManagement/mobileApps"
            $App = Invoke-RestMethod -Uri $uri -Method Post -ContentType "application/json" -Body $JSON -Headers $authToken
        }
        catch {
            $ex = $_.Exception
            $errorResponse = $ex.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($errorResponse)
            $reader.BaseStream.Position = 0
            $reader.DiscardBufferedData()
            $responseBody = $reader.ReadToEnd();
            Write-Host "Response content:`n$responseBody" -f Red
            Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
        }

        $properties = @{
            "mobileAppAssignments" = @(
                @{
                    "@odata.type" = "#microsoft.graph.mobileAppAssignment"
                    "target"      = @{
                        "@odata.type" = "#microsoft.graph.groupAssignmentTarget"
                        "groupId"     = $AADUserGroup.id
                    }
                    "intent"      = "required"
                }
            )
        }
        $JSON = $properties | ConvertTo-Json -Depth 3 -Compress

        #Assigns the Office 365 app to $UserGroup
        try {
            $uri = "https://graph.microsoft.com/Beta/deviceAppManagement/mobileApps/$($App.id)/assign"
            Invoke-RestMethod -Uri $uri -Headers $authToken -Method Post -Body $JSON -ContentType "application/json"
        }
        catch {
            $ex = $_.Exception
            $errorResponse = $ex.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($errorResponse)
            $reader.BaseStream.Position = 0
            $reader.DiscardBufferedData()
            $responseBody = $reader.ReadToEnd();
            Write-Host "Response content:`n$responseBody" -f Red
            Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
        }
    }
}

#Checks for temp directory for CD-files
$nocleanup = Test-Path $CDPath
If (!($nocleanup)) {
    New-Item $CDPath -ItemType Directory | Out-Null
}

#Downloads CD-Prod to tempdirectory and uploads to Intune
$OutFile = $CDPath + "\" + $CDForIntuneProd.Replace("https://raw.githubusercontent.com/Forsbakk/Blog/master/Contunuous%20delivery%20for%20Intune%20v2/Install/Install-CDforIntune/","")
Invoke-WebRequest -Uri $CDForIntuneProd -OutFile $OutFile

$FileItem = Get-Item -Path $OutFile
$encFile = [System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes("$OutFile"));

$properties = @{
    "@odata.type" = "#microsoft.graph.deviceManagementScript"
    "displayName" = $FileItem.Name
    "runSchedule" = @{
        "@odata.type" = "microsoft.graph.runSchedule"
    }
    "scriptContent" = $encFile
    "runAsAccount" = "system"
    "description" = "CD for Intune - Production"
    "enforceSignatureCheck" = $false
    "fileName" = $FileItem.Name
}
$JSON = $properties | ConvertTo-Json -Compress

try {
    $uri = "https://graph.microsoft.com/beta/deviceManagement/deviceManagementScripts"
    $prodscript = Invoke-RestMethod -Uri $uri -Headers $authToken -Method Post -Body $JSON -ContentType "application/json"
}
catch {
    $ex = $_.Exception
    $errorResponse = $ex.Response.GetResponseStream()
    $reader = New-Object System.IO.StreamReader($errorResponse)
    $reader.BaseStream.Position = 0
    $reader.DiscardBufferedData()
    $responseBody = $reader.ReadToEnd();
    Write-Host "Response content:`n$responseBody" -f Red
    Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
}
#Cleanup
Remove-Item $OutFile -Force

#Downloads CD-Beta to tempdirectory and uploads to Intune
$OutFile = $CDPath + "\" + $CDForIntuneBeta.Replace("https://raw.githubusercontent.com/Forsbakk/Blog/master/Contunuous%20delivery%20for%20Intune%20v2/Install/Install-CDforIntune/","")
Invoke-WebRequest -Uri $CDForIntuneBeta -OutFile $OutFile

$FileItem = Get-Item -Path $OutFile
$encFile = [System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes("$OutFile"));

$properties = @{
    "@odata.type" = "#microsoft.graph.deviceManagementScript"
    "displayName" = $FileItem.Name
    "runSchedule" = @{
        "@odata.type" = "microsoft.graph.runSchedule"
    }
    "scriptContent" = $encFile
    "runAsAccount" = "system"
    "description" = "CD for Intune - Beta"
    "enforceSignatureCheck" = $false
    "fileName" = $FileItem.Name
}
$JSON = $properties | ConvertTo-Json -Compress

try {
    $uri = "https://graph.microsoft.com/beta/deviceManagement/deviceManagementScripts"
    $betascript = Invoke-RestMethod -Uri $uri -Headers $authToken -Method Post -Body $JSON -ContentType "application/json"
}
catch {
    $ex = $_.Exception
    $errorResponse = $ex.Response.GetResponseStream()
    $reader = New-Object System.IO.StreamReader($errorResponse)
    $reader.BaseStream.Position = 0
    $reader.DiscardBufferedData()
    $responseBody = $reader.ReadToEnd();
    Write-Host "Response content:`n$responseBody" -f Red
    Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
}
#Cleanup
Remove-Item $OutFile -Force

#Assigns PowerShell-scripts to $UserGroup and $BetaUserGroup
$properties = @{
    "deviceManagementScriptGroupAssignments" = @(
        @{
            "@odata.type" = "#microsoft.graph.deviceManagementScriptGroupAssignment"
            "id" = $prodscript.id
            "targetGroupId" = $AADUserGroup.id
        }
    )
}
$JSON = $properties | ConvertTo-Json -Depth 3 -Compress

try {
    $uri = "https://graph.microsoft.com/beta/deviceManagement/deviceManagementScripts/$($prodscript.id)/assign"
    Invoke-RestMethod -Uri $uri -Headers $authToken -Method Post -Body $JSON -ContentType "application/json"
}
catch {
    $ex = $_.Exception
    $errorResponse = $ex.Response.GetResponseStream()
    $reader = New-Object System.IO.StreamReader($errorResponse)
    $reader.BaseStream.Position = 0
    $reader.DiscardBufferedData()
    $responseBody = $reader.ReadToEnd();
    Write-Host "Response content:`n$responseBody" -f Red
    Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
}

$properties = @{
    "deviceManagementScriptGroupAssignments" = @(
        @{
            "@odata.type" = "#microsoft.graph.deviceManagementScriptGroupAssignment"
            "id" = $betascript.id
            "targetGroupId" = $BetaAADGroup.id
        }
    )
}
$JSON = $properties | ConvertTo-Json -Depth 3 -Compress

try {
    $uri = "https://graph.microsoft.com/beta/deviceManagement/deviceManagementScripts/$($betascript.id)/assign"
    Invoke-RestMethod -Uri $uri -Headers $authToken -Method Post -Body $JSON -ContentType "application/json"
}
catch {
    $ex = $_.Exception
    $errorResponse = $ex.Response.GetResponseStream()
    $reader = New-Object System.IO.StreamReader($errorResponse)
    $reader.BaseStream.Position = 0
    $reader.DiscardBufferedData()
    $responseBody = $reader.ReadToEnd();
    Write-Host "Response content:`n$responseBody" -f Red
    Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
}
#Cleanup
If (!($nocleanup)) {
    Remove-Item $CDPath -Force
}