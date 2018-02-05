$Script = @"
function Install-EXE {
    Param(
        `$AppName,
        `$Installer,
        `$InstArgs,
        `$Uninstaller,
        `$UninstArgs,
        `$appLocURL,
        `$wrkDir,
        `$detection,
        `$Mode
    )
    If (`$mode -eq "Install") { #INSTALL MODE
        Write-Host "Starting installation script for `$AppName"
        Write-Host "Detecting previous installations"
    
        If (!(Test-Path `$detection)) { #Detects if current version is installed
    
            Write-Host "`$AppName is not detected, starting install"

            Invoke-WebRequest -Uri `$appLocURL -OutFile `$wrkDir\`$Installer #Download the installer
            Start-Process -FilePath `$wrkDir\`$Installer -ArgumentList `$InstArgs -Wait #Start the installer
            Remove-Item -Path `$wrkDir\`$Installer -Force #Clean up installation file
            If (!(Test-Path `$detection)) {
                Write-Error "`$AppName not detected after installation" #Give error if application is not installed after installation
            }
        }
        Else { #App already detected
            Write-Host "`$AppName detected, will NOT install"
        }
    }
    elseif (`$mode -eq "Uninstall") { #UNINSTALL MODE
        If (Test-Path `$Uninstaller) {
            Start-Process `$Uninstaller -ArgumentList `$UninstArgs -Wait
        }
        Else {
            Write-Error "Could not find uninstaller, aborting" #Give error if uninstaller is not present
        }
    }
}

function Install-SC {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=`$true)]
        [string]`$SCName,
        [Parameter(Mandatory=`$true)]
        [ValidateSet("url","lnk")]
        [string]`$SCType,
        [Parameter(Mandatory=`$true)]
        [string]`$Path,
        [string]`$WorkingDir = `$null,
        [string]`$Arguments = `$null,
        [string]`$IconFileandType = `$null,
        [string]`$Description = `$null,
        [string]`$Mode
    )
    If (`$Mode -eq "Uninstall") {
        `$FileToDelete = `$env:PUBLIC + "\Desktop\`$SCName.`$SCType"
        Remove-Item `$FileToDelete -Force
    }
    Elseif (`$Mode -eq "Install") {
        If (`$SCType -eq "lnk") {
            `$verPath = `$WorkingDir + "\" + `$Path
            `$Detection = Test-Path `$verPath
            If (!(`$Detection)) { 
                `$verPath = `$Path
                `$Detection = Test-Path `$verPath
                If (!(`$Detection)) { 
                    `$verPath = `$Path -split ' +(?=(?:[^\"]*\"[^\"]*\")*[^\"]*`$)'
                    `$verPath = `$verPath[0] -replace '"',''
                    `$Detection = Test-Path `$verPath
                }
            }
        }
        Else {
            `$Detection = "url-file"
        }
        If (!(`$Detection)) {
            Write-Error "Can't detect SC-endpoint, skipping"
        }
        else {
            If (Test-Path (`$env:PUBLIC + "\Desktop\`$SCName.`$SCType")) {
                Write-Output "SC already exists, skipping"
            }
            else {
                `$ShellObj = New-Object -ComObject ("WScript.Shell")
                `$SC = `$ShellObj.CreateShortcut(`$env:PUBLIC + "\Desktop\`$SCName.`$SCType")
                `$SC.TargetPath="`$Path"
                If (`$WorkingDir.Length -ne 0) {
                    `$SC.WorkingDirectory = "`$WorkingDir";
                }
                If (`$Arguments.Length -ne 0) {
                    `$SC.Arguments = "`$Arguments";
                }
                If (`$IconFileandType.Length -ne 0) {
                    `$SC.IconLocation = "`$IconFileandType";
                }
                If (`$Description.Length -ne 0) {
                    `$SC.Description  = "`$Description";
                }
                `$SC.Save()
            }
        }
    }
}

`$AppConfig = `$env:TEMP + "\AppConfig.JSON"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Forsbakk/Blog/master/Continous%20Delivery%20for%20Intune/Applications/config.json" -OutFile `$AppConfig
`$Applications = Get-Content `$AppConfig | ConvertFrom-Json

foreach (`$app in `$Applications) {
    Install-EXE -AppName `$app.Name -Installer `$app.Installer -InstArgs `$app.InstArgs -Uninstaller `$app.Uninstaller -UninstArgs `$app.UninstArgs -appLocURL `$app.appLocURL -wrkDir `$app.wrkDir -detection `$app.detection -Mode `$app.Mode
}

Remove-Item `$AppConfig -Force

`$SCConfig = `$env:TEMP + "\SCConfig.JSON"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Forsbakk/Blog/master/Continous%20Delivery%20for%20Intune/Shortcuts/config.json" -OutFile `$SCConfig
`$SCs = Get-Content `$SCConfig | ConvertFrom-Json

foreach (`$sc in `$SCs) {
    Install-SC -SCName `$sc.Name -SCType `$sc.Type -Path `$sc.Path -WorkingDir `$sc.WorkingDir -Arguments `$sc.Arguments -IconFileandType `$sc.IconFileandType -Description `$sc.Description -Mode `$sc.Mode
}

Remove-Item `$SCConfig -Force
"@


If (!(Test-Path "C:\Windows\Scripts")) {
    New-Item "C:\Windows\Scripts" -ItemType Directory
}
$Script | Out-File "C:\Windows\Scripts\Start-ContinousDelivery.ps1"

$User = "SYSTEM"
$Action = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument "-Executionpolicy Bypass -File `"C:\Windows\Scripts\Start-ContinousDelivery.ps1`""
$Trigger = New-ScheduledTaskTrigger -AtLogOn
Register-ScheduledTask -Action $Action -Trigger $Trigger -User $User -RunLevel Highest -TaskName "Continous Delivery for Intune"