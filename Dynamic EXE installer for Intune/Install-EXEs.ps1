#
#Install-EXEs.ps1
#Installs EXE applications with Microsoft Intune
#04.02.2018
#http://blog.forsbakk.priv.no/
#
function Install-EXE {
    Param(
        $AppName,
        $Installer,
        $InstArgs,
        $Uninstaller,
        $UninstArgs,
        $appLocURL,
        $wrkDir,
        $detection,
        $Mode
    )
    If ($mode -eq "Install") { #INSTALL MODE
        Write-Host "Starting installation script for $AppName"
        Write-Host "Detecting previous installations"
    
        If (!(Test-Path $detection)) { #Detects if current version is installed
    
            Write-Host "$AppName is not detected, starting install"

            Invoke-WebRequest -Uri $appLocURL -OutFile $wrkDir\$Installer #Download the installer
            Start-Process -FilePath $wrkDir\$Installer -ArgumentList $InstArgs -Wait #Start the installer
            Remove-Item -Path $wrkDir\$Installer -Force #Clean up installation file
            If (!(Test-Path $detection)) {
                Write-Error "$AppName not detected after installation" #Give error if application is not installed after installation
            }
        }
        Else { #App already detected
            Write-Host "$AppName detected, will NOT install"
        }
    }
    elseif ($mode -eq "Uninstall") { #UNINSTALL MODE
        If (Test-Path $Uninstaller) {
            Start-Process $Uninstaller -ArgumentList $UninstArgs -Wait
        }
        Else {
            Write-Error "Could not find uninstaller, aborting" #Give error if uninstaller is not present
        }
    }
}
$AppConfig = $env:TEMP + "\AppConfig.JSON"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Forsbakk/Blog/master/Dynamic%20EXE%20installer%20for%20Intune/config.json" -OutFile $AppConfig
$Applications = Get-Content $AppConfig | ConvertFrom-Json
foreach ($app in $Applications) {
    Install-EXE -AppName $app.Name -Installer $app.Installer -InstArgs $app.InstArgs -Uninstaller $app.Uninstaller -UninstArgs $app.UninstArgs -appLocURL $app.appLocURL -wrkDir $($app.wrkDir) -detection $app.detection -Mode $app.Mode
}