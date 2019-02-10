#Path variables
[string]$IntuneWinBin = ".\IntuneWin\bin\IntuneWinAppUtil.exe" #Path to IntuneWinAppUtil.exe
[string]$ToolkitPath = ".\IntuneWin\Toolkit" #Path to PowerShell App Deployment Toolkit
[string]$AppPath = "" #Path to Application source

#Toolkit variables
[string]$appVendor = 'Custom Vendor'
[string]$appName = 'MyApplication'
[string]$appVersion = '1.0.0'
[string]$appScriptAuthor = 'Author'

#If $true then creates a detection in registry < "HKLM\SOFTWARE\$appVendor\$appName" Version eq $appVersion >
[bool]$CreateRegistryDetection = $true

#Defines which processes should be closed prior to installation. Write $false if that is not a requirement
[string]$appsToClose = "winword,excel,powerpnt,outlook"

#Pre-installation
[scriptblock]$preinst = {
    Remove-MSIApplications -Name "MyApplication"
}
#Installation script
[scriptblock]$installation = {
    $items = Get-ChildItem -Path $dirFiles
    foreach ($i in $items) {
        Execute-MSI -Action 'Install' -Path "$($i.Name)" -Parameters '/QN' -SkipMSIAlreadyInstalledCheck
    }
    Set-RegistryKey -Key "HKEY_LOCAL_MACHINE\SOFTWARE\CustomVendor" -Name "Config" -Value "C:\temp\Config.ini"
}

#Pre-uninstallation
[scriptblock]$preuninst = {

}
#Uninstallation script
[scriptblock]$uninstallation = {
    $items = Get-ChildItem -Path $dirFiles | Where-Object { $_.Name -notlike "*msxml.msi" }
    foreach ($i in $items) {
        Execute-MSI -Action 'Uninstall' -Path "$($i.Name)" -Parameters '/QN' -SkipMSIAlreadyInstalledCheck
    }
}

#Script start
$SetupWithToolkit = "$AppPath\ToolkitInstallation"
$IntuneWinDestination = "$AppPath\IntuneWin"

#Creating folders and copying content
if (!(Test-Path $SetupWithToolkit)) {
    New-Item -Path $SetupWithToolkit -ItemType Directory
}
Copy-Item -Path "$ToolkitPath/*" -Destination "$SetupWithToolkit" -Recurse

New-Item -Path "$SetupWithToolkit/Files" -ItemType Directory
Copy-Item -Path "$AppPath/*" -Destination "$SetupWithToolkit/Files" -Recurse -Exclude "ToolkitInstallation","IntuneWin"

#Getting script and date
$DeployScript = Get-Content "$SetupWithToolkit/Deploy-Application.ps1"
$Date = (Get-Date -Format "dd/MM/yyyy").ToString()

#Replace variables
$DeployScript = $DeployScript.Replace("[string]`$appVendor = ''","[string]`$appVendor = '$appVendor'")
$DeployScript = $DeployScript.Replace("[string]`$appName = ''","[string]`$appName = '$appName'")
$DeployScript = $DeployScript.Replace("[string]`$appVersion = ''","[string]`$appVersion = '$appVersion'")
$DeployScript = $DeployScript.Replace("[string]`$appScriptDate = '02/12/2017'","[string]`$appScriptDate = '$Date'")
$DeployScript = $DeployScript.Replace("[string]`$appScriptAuthor = '<author name>'","[string]`$appScriptAuthor = '$appScriptAuthor'")

#Setting $appsToClose
if ($appsToClose -ne $false) {
    $DeployScript = $DeployScript.Replace("Show-InstallationWelcome -CloseApps 'iexplore' -AllowDefer -DeferTimes 3 -CheckDiskSpace -PersistPrompt","Show-InstallationWelcome -CloseApps '$appsToClose' -BlockExecution")
    $DeployScript = $DeployScript.Replace("Show-InstallationWelcome -CloseApps 'iexplore' -CloseAppsCountdown 60","Show-InstallationWelcome -CloseApps '$appsToClose' -BlockExecution")
}
else {
    $DeployScript = $DeployScript.Replace("Show-InstallationWelcome -CloseApps 'iexplore' -AllowDefer -DeferTimes 3 -CheckDiskSpace -PersistPrompt","")
    $DeployScript = $DeployScript.Replace("Show-InstallationWelcome -CloseApps 'iexplore' -CloseAppsCountdown 60","")
}

#Replace (un)installation tasks
$DeployScript = $DeployScript.Replace("## <Perform Pre-Installation tasks here>",$preinst)
$DeployScript = $DeployScript.Replace("## <Perform Installation tasks here>",$installation)
$DeployScript = $DeployScript.Replace("## <Perform Pre-Uninstallation tasks here>",$preuninst)
$DeployScript = $DeployScript.Replace("# <Perform Uninstallation tasks here>",$uninstallation)

#Creates detection in registry
if ($CreateRegistryDetection -eq $true) {
    $DeployScript = $DeployScript.Replace("## <Perform Post-Installation tasks here>","Set-RegistryKey -Key `"HKEY_LOCAL_MACHINE\SOFTWARE\$appVendor\$appName`" -Name `"Version`" -Value `"$appVersion`"")
    $DeployScript = $DeployScript.Replace("## <Perform Post-Uninstallation tasks here>","Set-RegistryKey -Key `"HKEY_LOCAL_MACHINE\SOFTWARE\$appVendor\$appName`" -Name `"Version`" -Value `"Uninstalled`"")
}

#Set new content
Set-Content -Path "$SetupWithToolkit/Deploy-Application.ps1" -Value $DeployScript

#Create intunewin file
Start-Process $IntuneWinBin -ArgumentList "-c `"$SetupWithToolkit`" -s `"Deploy-Application.exe`" -o `"$IntuneWinDestination`" -q" -Wait

#Rename the file to something less stupid
Rename-Item -Path "$IntuneWinDestination\Deploy-Application.intunewin" "$($appVendor.Replace(" ","_"))_$($appName.Replace(" ","_")).intunewin"