#
#Install-GIMP.ps1
#Installs EXE applications in Microsoft Intune
#04.02.2018
#http://blog.forsbakk.priv.no/
#
$AppName = "GIMP 2" #Application name
$Installer = "gimp-2.8.22-setup.exe" #Installer file
$InstArgs = "/verysilent" #Arguments for silent installation
$Uninstaller = "C:\Program Files\GIMP 2\uninst\unins000.exe" #Uninstaller file
$UninstArgs = "/verysilent" #Arguments for silent uninstallation
$appLocURL = "https://www.mirrorservice.org/sites/ftp.gimp.org/pub/gimp/v2.8/windows/gimp-2.8.22-setup.exe" #Download location
$wrkDir = $env:TEMP #Temporary store for our EXE
$detection = "C:\Program Files\GIMP 2\bin\gimp-2.8.exe" #Detection file
$Mode = "Install" #Install or Uninstall

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