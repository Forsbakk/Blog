$BranchName = " "
$Version = " "

#added some config

function Write-Log {
    Param(
        [string]$Value,
        [string]$Severity,
        [string]$Component = "CD4Intune",
        [string]$FileName = "CD4Intune.log"
    )
    $LogFilePath = "C:\Windows\Logs" + "\" + $FileName
    $Time = -join @((Get-Date -Format "HH:mm:ss.fff"), "+", (Get-WmiObject -Class Win32_TimeZone | Select-Object -ExpandProperty Bias))
    $Date = (Get-Date -Format "MM-dd-yyyy")
    $LogText = "<![LOG[$($Value)]LOG]!><time=""$($Time)"" date=""$($Date)"" component=""$($Component)"" context=""SYSTEM"" type=""$($Severity)"" thread=""$($PID)"" file="""">"
    try {
        Out-File -InputObject $LogText -Append -NoClobber -Encoding Default -FilePath $LogFilePath -ErrorAction Stop
    }
    catch [System.Exception] {
        Write-Warning -Message "Unable to append log entry to $FileName file. Error message: $($_.Exception.Message)"
    }
}


$cfg = Invoke-RestMethod -Uri "https://raw.githubusercontent.com/Forsbakk/Blog/master/Contunuous%20delivery%20for%20Intune%20v2/versioncontrol/config.json" -UseBasicParsing
$cfg = $cfg | Where-Object { $_.Name -eq $BranchName }

if ($cfg.Version -eq $Version) {
    Write-Log -Value "Newest version already installed" -Severity 1 -Component "Update"
}
else {
    Write-Log -Value "Newer version found, upgrading" -Severity 1 -Component "Update"

    $ScriptLocURI = "https://raw.githubusercontent.com/Forsbakk/Blog/master/Contunuous delivery for Intune v2/Install/Install-CDforIntune/Install-CDforIntune.ps1"
    Invoke-WebRequest -Uri $ScriptLocURI -OutFile "$env:TEMP\Install-CDforIntune.ps1"

    Start-Process "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -File `"$env:TEMP\Install-CDforIntune.ps1`" -BranchName $BranchName -WaitFor $PID -CleanUp $true" -WindowStyle Hidden
    break
}


$SerialNumber = Get-WmiObject -Class Win32_bios | Select-Object -ExpandProperty SerialNumber

$CurrentName = $env:COMPUTERNAME
If (!($CurrentName -eq $SerialNumber)) {
    Rename-Computer -ComputerName $CurrentName -NewName $SerialNumber -Force
}


$ChocoBin = $env:ProgramData + "\Chocolatey\bin\choco.exe"

if (!(Test-Path -Path $ChocoBin)) {
    Write-Log -Value "$ChocoBin not detected; starting installation of chocolatey" -Severity 2 -Component "Chocolatey"
    try {
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
    }
    catch {
        Write-Log -Value "Failed to install chocolatey" -Severity 3 -Component "Chocolatey"
    }
}

Write-Log -Value "Upgrading chocolatey and all existing packages" -Severity 1 -Component "Chocolatey"
try {
    Invoke-Expression "cmd /c $ChocoBin upgrade all -y" -ErrorAction Stop
}
catch {
    Write-Log -Value "Failed to upgrade chocolatey and all existing packages" -Severity 3 -Component "Chocolatey"
}

$ChocoConf = Invoke-RestMethod -Uri "https://raw.githubusercontent.com/Forsbakk/Blog/master/Contunuous%20delivery%20for%20Intune%20v2/$BranchName/Choco/config.json" -UseBasicParsing

ForEach ($ChockoPkg in $ChocoConf) {
    Write-Log -Value "Running $($ChockoPkg.Mode) on $($ChockoPkg.Name)" -Severity 1 -Component "Chocolatey"
    try {
        Invoke-Expression "cmd /c $ChocoBin $($ChockoPkg.Mode) $($ChockoPkg.Name) -y" -ErrorAction Stop
    }
    catch {
        Write-Log -Value "Failed to run $($ChockoPkg.Mode) on $($ChockoPkg.Name)" -Severity 3 -Component "Chocolatey"
    }
}


$AdvInstallers = Invoke-RestMethod -Uri "https://raw.githubusercontent.com/Forsbakk/Blog/master/Contunuous%20delivery%20for%20Intune%20v2/$BranchName/Custom%20Execution/config.json" -UseBasicParsing

foreach ($AdvInst in $AdvInstallers) {

    [string]$Name = $AdvInst.Name
    [psobject]$FilesToDwnload = $AdvInst.FilesToDwnload
    [psobject]$Execution = $AdvInst.Execution
    [psobject]$Detection = $AdvInst.Detection
    [string]$wrkDir = $AdvInst.wrkDir

    $DetectionRulesCount = $Detection | Measure-Object | Select-Object -ExpandProperty Count
    $DetectionCounter = 0

    Write-Log -Value "Starting detection of $Name" -Severity 1 -Component "AdvancedApplication"

    foreach ($detect in $Detection) {
        $DetectionRule = $detect | Select-Object -ExpandProperty Rule
        $runDetectionRule = Invoke-Expression -Command $DetectionRule
        if ($runDetectionRule -eq $true) {
            $DetectionCounter++
        }
    }

    If (!($DetectionRulesCount -eq $DetectionCounter)) {
        Write-Log -Value "$Name is not detected; starting installation" -Severity 1 -Component "AdvancedApplication"
        foreach ($dwnload in $FilesToDwnload) {
            $URL = $dwnload | Select-Object -ExpandProperty URL
            $FileName = $dwnload | Select-Object -ExpandProperty FileName
            Write-Log -Value "Downloading $URL" -Severity 1 -Component "AdvancedApplication"
            Invoke-WebRequest -Uri $URL -OutFile $wrkDir\$FileName
            Write-Log -Value "$URL downloaded" -Severity 1 -Component "AdvancedApplication"
        }
        foreach ($Execute in $Execution) {
            $Program = $Execute | Select-Object -ExpandProperty Execute
            $Arguments = $Execute | Select-Object -ExpandProperty Arguments
            Write-Log -Value "Executing $Program with arguments $Arguments" -Severity 1 -Component "AdvancedApplication"
            Start-Process -FilePath $Program -ArgumentList $Arguments -Wait
            Write-Log -Value "$Program completed" -Severity 1 -Component "AdvancedApplication"
        }
        foreach ($dwnload in $FilesToDwnload) {
            $FileName = $dwnload | Select-Object -ExpandProperty FileName
            Remove-Item $wrkDir\$FileName -Force
        }
        Write-Log -Value "Installation of $Name completed" -Severity 1 -Component "AdvancedApplication"
    }
    else {
        Write-Log -Value "$Name is already installed; skipping" -Severity 1 -Component "AdvancedApplication"
    }
}


$PSs = Invoke-RestMethod -Uri "https://raw.githubusercontent.com/Forsbakk/Blog/master/Contunuous%20delivery%20for%20Intune%20v2/$BranchName/PowerShell/config.json" -UseBasicParsing

foreach ($PS in $PSs) {
    $runDetectionRule = Invoke-Expression -Command $PS.Detection
    Write-Log -Value "Detecting $($PS.Name)" -Severity 1 -Component "PowerShell"
    if (!($runDetectionRule -eq $true)) {
        $Arguments = "-Command $($PS.Command)"
        Write-Log -Value "Starting powershell.exe with arguments:$($Arguments)" -Severity 1 -Component "PowerShell"
        Start-Process -FilePath "powershell.exe" -ArgumentList $PS.Arguments
    }
    else {
        Write-Log -Value "$($PS.Name) is already run" -Severity 1 -Component "PowerShell"
    }
}


$SCConf = Invoke-RestMethod -Uri "https://raw.githubusercontent.com/Forsbakk/Blog/master/Contunuous%20delivery%20for%20Intune%20v2/$BranchName/Shortcuts/config.json" -UseBasicParsing

ForEach ($SC in $SCConf) {
    If ($SC.Mode -eq "Uninstall") {
        Write-Log -Value "Starting deletion of $($SC.Name)" -Severity 1 -Component "SC"
        $FileToDelete = $env:PUBLIC + "\Desktop\$($SC.Name).$($SC.Type)"
        Remove-Item $FileToDelete -Force
        Write-Log -Value "$($SC.Name) deleted" -Severity 1 -Component "SC"
    }
    Elseif ($SC.Mode -eq "Install") {
        Write-Log -Value "Starting detection of $($SC.Name)" -Severity 1 -Component "SC"
        If ($SC.Type -eq "lnk") {
            $verPath = $SC.WorkingDir + "\" + $SC.Path
            $Detection = Test-Path $verPath
            If (!($Detection)) {
                $verPath = $SC.Path
                $Detection = Test-Path $verPath
                If (!($Detection)) {
                    $verPath = $SC.Path -split ' +(?=(?:[^\"]*\"[^\"]*\")*[^\"]*$)'
                    $verPath = $verPath[0] -replace '"', ''
                    $Detection = Test-Path $verPath
                }
            }
        }
        Else {
            $Detection = "url-file"
        }
        If (!($Detection)) {
            Write-Log -Value "Can not detect $($SC.Name) endpoint; skipping" -Severity 2 -Component "SC"
        }
        else {
            If (Test-Path ($env:PUBLIC + "\Desktop\$($SC.Name).$($SC.Type)")) {
                Write-Log -Value "$($SC.Name) already exists; skipping" -Severity 1 -Component "SC"
            }
            else {
                Write-Log -Value "$($SC.Name) is not detected; starting installation" -Severity 1 -Component "SC"
                $ShellObj = New-Object -ComObject ("WScript.Shell")
                $Shortcut = $ShellObj.CreateShortcut($env:PUBLIC + "\Desktop\$($SC.Name).$($SC.Type)")
                $Shortcut.TargetPath = "$($SC.Path)"
                If ($SC.WorkingDir) {
                    $Shortcut.WorkingDirectory = "$($SC.WorkingDir)";
                }
                If ($SC.Arguments) {
                    $Shortcut.Arguments = "$($SC.Arguments)";
                }
                If ($SC.IconFileandType) {
                    $Shortcut.IconLocation = "$($SC.IconFileandType)";
                }
                If ($SC.Description) {
                    $Shortcut.Description = "$($SC.Description)";
                }
                $Shortcut.Save()
                Write-Log -Value "$($SC.Name) is installed" -Severity 1 -Component "SC"
            }
        }
    }
}


$regfiles = Invoke-RestMethod -Uri "https://raw.githubusercontent.com/Forsbakk/Blog/master/Contunuous%20delivery%20for%20Intune%20v2/$BranchName/Regedit/config.json" -UseBasicParsing

ForEach ($regfile in $regfiles) {
    Write-Log -Value "Starting detection of Regedit settings; $($regfile.URL)" -Severity 1 -Component "Regedit"
    $runDetectionRule = Invoke-Expression -Command $regfile.detection
    If (!($runDetectionRule -eq $true)) {
        Write-Log -Value "Regedit settings not detected; starting install; $($regfile.URL)" -Severity 1 -Component "Regedit"
        if ($regfile.Type -eq "HKLM") {
            Write-Log -Value "Regedit settings is HKLM; $($regfile.URL)" -Severity 1 -Component "Regedit"
            $TempHKLMFile = $env:TEMP + "\TempHKLM.reg"
            Remove-Item $TempHKLMFile -Force -ErrorAction Ignore
            Invoke-WebRequest -Uri $($regfile.URL) -OutFile $TempHKLMFile
            $Arguments = "/s $TempHKLMFile"
            Start-Process "regedit.exe" -ArgumentList $Arguments -Wait
            Remove-Item $TempHKLMFile -Force
            Write-Log -Value "HKLM file installed; $($regfile.URL)" -Severity 1 -Component "Regedit"
        }
        elseif ($regfile.Type -eq "HKCU") {
            Write-Log -Value "Regedit settings is HKCU; $($regfile.URL)" -Severity 1 -Component "Regedit"
            $TempHKCUFile = $env:TEMP + "\TempHKCU.reg"
            Remove-Item $TempHKCUFile -Force -ErrorAction Ignore
            Invoke-WebRequest -Uri $($regfile.URL) -OutFile $TempHKCUFile
            $regfile = Get-Content $TempHKCUFile
            $hives = Get-ChildItem -Path REGISTRY::HKEY_USERS | Select-Object -ExpandProperty Name
            foreach ($hive in $hives) {
                if (!($hive -like "*_Classes")) {
                    $newregfile = $regfile -replace "HKEY_CURRENT_USER", $hive
                    Set-Content -Path $TempHKCUFile -Value $newregfile
                    $Arguments = "/s $TempHKCUFile"
                    Start-Process "regedit.exe" -ArgumentList $Arguments -Wait
                }
            }
            Remove-Item $TempHKCUFile -Force
            Write-Log -Value "HKCU file installed; $($regfile.URL)" -Severity 1 -Component "Regedit"
        }
    }
    Else {
        Write-Log -Value "Regedit settings is detected, aborting install; $($regfile.URL)" -Severity 1 -Component "Regedit"
    }
}