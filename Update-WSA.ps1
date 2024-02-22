[CmdletBinding()]
Param()

Begin {
    Function Exit-WithCode {
        Param(
            [System.Int32]
            $Code = 0,
            [System.String]
            $Message = "",
            [Switch]
            $Throw = $False
        )

        If ($Throw) {
            Write-Error -Message $Message;
            $Code = 1;
        }
        Pop-Location -ErrorAction SilentlyContinue;
        Exit $Code
    }

    Function Write-Header {
        Write-Host -ForegroundColor Red   "#############################################################################################################";
        Write-Host -ForegroundColor Red   "#                                                                                                           #";
        Write-Host -ForegroundColor Red   "# " -NoNewLine;
        Write-Host -ForegroundColor White   "Be sure to backup your save file!!!" -NoNewLine;
        Write-Host -ForegroundColor Red                                        "                                                                       #";
        Write-Host -ForegroundColor Red   "#                                                                                                           #";
        Write-Host -ForegroundColor Red   "#############################################################################################################";
        Write-Host -ForegroundColor Green "https://github.com/MustardChef/WSABuilds/blob/master/Documentation/WSABuilds/Backup%20and%20Restore.md";
        $Confirm = (Read-Host -Prompt "Continue (Y/N)")
        If ($Confirm -match "[Yy](?:[Ee][Ss])?") {
            Return $True;
        }
        Return $False;
    }
    $script:TempFolder = (Join-Path -Path $HOME -ChildPath "Downloads" -AdditionalChildPath @("n", "WSA-temp"));
    If (Test-Path -LiteralPath $script:TempFolder -PathType Container) {
       Remove-Item -Recurse $script:TempFolder -ErrorAction Stop;
    }
    New-Item -Path $script:TempFolder -ItemType Directory -ErrorAction Stop | Out-Null;
    Push-Location $script:TempFolder;
    Stop-Service "WSAService" -ErrorAction SilentlyContinue;
}
Process {
    If (-not (Write-Header)) {
        Exit-WithCode -Code 0
    }
    $WindowsSubsystemForAndroidDirectory = ((Get-ChildItem -Path (Join-Path -Path $env:LocalAppData -ChildPath "Packages") -Directory) | Where-Object { $_.BaseName -match ".*\.WindowsSubsystemForAndroid_.*" });

    If ($WindowsSubsystemForAndroidDirectory.Count -gt 1) {
        Exit-WithCode -Throw -Message "Too many Windows Subsystem For Android Directories found in `"$(Join-Path -Path $env:LocalAppData -ChildPath "Packages")`"...";
    }

    $BackupItems = (Get-ChildItem -Path (Join-Path -Path $WindowsSubsystemForAndroidDirectory.FullName -ChildPath "LocalCache") -File -Filter "*.vhdx");

    ForEach ($Item in $BackupItems) {
        Copy-Item -Path $Item.FullName -Destination (Join-Path -Path $script:TempFolder -ChildPath $_.Name) -ErrorAction Stop;
    }

    Try {
        $Latest = (Invoke-RestMethod -Uri "https://api.github.com/repos/MustardChef/WSABuilds/releases");

        If ($Null -eq $Latest) {
            Exit-WithCode -Throw -Message "Failed to find latest releases."
        }

        $DownloadUri = ($Latest.Where({ $_.name.Contains("Windows 11 x64") })[0].assets.Where({ $_.name.Contains("with-Magisk") -and $_.name.Contains("MindTheGapps") })[0].browser_download_url);

        If ($Null -eq $DownloadUri) {
            Exit-WithCode -Throw -Message "Failed to find download uri."
        }

        Try {
            $DownloadFile = (Invoke-WebRequest -Uri $DownloadUri -ErrorAction Stop -SkipHttpErrorCheck -PassThru -OutFile (Join-Path -Path $script:TempFolder -ChildPath "wsa.7z"))
        } Catch {
            Exit-WithCode -Throw -Message $_.Exception.Message;
        }
    } Catch {
       Exit-WithCode -Throw -Message $_.Exception.Message;
    }

    & "$(Get-Command -Name "7z" -ErrorAction Stop)" x "$(Join-Path -Path $script:TempFolder -ChildPath "wsa.7z")"

    $script:WSAFolder = (Get-ChildItem -Path $script:TempFolder -Directory | Where-Object { $_.Name.StartsWith("WSA_") });

    Stop-Service "WSAService" -ErrorAction Stop;

    Start-Process -Verb RunAs -FilePath (Get-Command -Name "powershell").Source -WorkingDirectory $script:WSAFolder -ArgumentList @("-Command", "Get-AppxPackage `"[I]MicrosoftCorporationII.WindowsSubsystemForAndroid[/I]`" | Remove-AppxPackage;Get-ChildItem -ErrorAction Stop -Path `"C:\WSA`" | ForEach-Object { Remove-Item -Recurse -Force -ErrorAction Stop -Path `$_.FullName };Get-ChildItem -ErrorAction Stop -Path `"$($script:WSAFolder)`" | ForEach-Object { Move-Item -Force -ErrorAction Stop -Path `$_.FullName -Destination (Join-Path -Path `"C:\WSA`" -ChildPath `"`$_.Name`") };") -ErrorAction Stop -Wait;

    $script:WSAFolder = "C:\WSA"

    Pop-Location
    Push-Location $script:WSAFolder

    $InstallPs1PrePatch = (Get-Content -Path (Get-Item -Path (Join-Path -Path $script:WSAFolder -ChildPath "Install.ps1")) -Raw);
    $_SettingsApp           = ($InstallPs1PrePatch | Select-String -Pattern " *Start-Process `"shell:AppsFolder\\MicrosoftCorporationII\.WindowsSubsystemForAndroid_8wekyb3d8bbwe\!SettingsApp`"");
    $_ComAndroidSettings    = ($InstallPs1PrePatch | Select-String -Pattern " *Start-Process `"wsa:\/\/com\.android\.settings`"");
    $_ComTopJohnWuMagisk    = ($InstallPs1PrePatch | Select-String -Pattern " *Start-Process `"wsa:\/\/com\.topjohnwu\.magisk`"");
    $_IoGitHubHuskyDgMagisk = ($InstallPs1PrePatch | Select-String -Pattern " *Start-Process `"wsa:\/\/io\.github\.huskydg\.magisk`"");
    $_IoGitHubVvb2060Magisk = ($InstallPs1PrePatch | Select-String -Pattern " *Start-Process `"wsa:\/\/io\.github\.vvb2060\.magisk`"");
    $_ComAndroidVending     = ($InstallPs1PrePatch | Select-String -Pattern " *Start-Process `"wsa:\/\/com\.android\.vending`"");
    $_ComAndroidVenezia     = ($InstallPs1PrePatch | Select-String -Pattern " *Start-Process `"wsa:\/\/com\.amazon\.venezia`"");

    If ($_SettingsApp.Matches.Count -gt 0) {
        $InstallPs1PrePatch = ($InstallPs1PrePatch -Replace " *Start-Process `"shell:AppsFolder\\MicrosoftCorporationII\.WindowsSubsystemForAndroid_8wekyb3d8bbwe\!SettingsApp`"", "");
    }
    If ($_ComAndroidSettings.Matches.Count -gt 0) {
        $InstallPs1PrePatch = ($InstallPs1PrePatch -Replace " *Start-Process `"wsa:\/\/com\.android\.settings`"", "");
    }
    If ($_ComTopJohnWuMagisk.Matches.Count -gt 0) {
        $InstallPs1PrePatch = ($InstallPs1PrePatch -Replace " *Start-Process `"wsa:\/\/com\.topjohnwu\.magisk`"", "");
    }
    If ($_IoGitHubHuskyDgMagisk.Matches.Count -gt 0) {
        $InstallPs1PrePatch = ($InstallPs1PrePatch -Replace " *Start-Process `"wsa:\/\/io\.github\.huskydg\.magisk`"", "");
    }
    If ($_IoGitHubVvb2060Magisk.Matches.Count -gt 0) {
        $InstallPs1PrePatch = ($InstallPs1PrePatch -Replace " *Start-Process `"wsa:\/\/io\.github\.vvb2060\.magisk`"", "");
    }
    If ($_ComAndroidVending.Matches.Count -gt 0) {
        $InstallPs1PrePatch = ($InstallPs1PrePatch -Replace " *Start-Process `"wsa:\/\/com\.android\.vending`"", "");
    }
    If ($_ComAndroidVenezia.Matches.Count -gt 0) {
        $InstallPs1PrePatch = ($InstallPs1PrePatch -Replace " *Start-Process `"wsa:\/\/com\.amazon\.venezia`"", "");
    }
    $_SettingsApp           = ($InstallPs1PrePatch | Select-String -Pattern " *Start-Process `"shell:AppsFolder\\MicrosoftCorporationII\.WindowsSubsystemForAndroid_8wekyb3d8bbwe\!SettingsApp`"");
    $_ComAndroidSettings    = ($InstallPs1PrePatch | Select-String -Pattern " *Start-Process `"wsa:\/\/com\.android\.settings`"");
    $_ComTopJohnWuMagisk    = ($InstallPs1PrePatch | Select-String -Pattern " *Start-Process `"wsa:\/\/com\.topjohnwu\.magisk`"");
    $_IoGitHubHuskyDgMagisk = ($InstallPs1PrePatch | Select-String -Pattern " *Start-Process `"wsa:\/\/io\.github\.huskydg\.magisk`"");
    $_IoGitHubVvb2060Magisk = ($InstallPs1PrePatch | Select-String -Pattern " *Start-Process `"wsa:\/\/io\.github\.vvb2060\.magisk`"");
    $_ComAndroidVending     = ($InstallPs1PrePatch | Select-String -Pattern " *Start-Process `"wsa:\/\/com\.android\.vending`"");
    $_ComAndroidVenezia     = ($InstallPs1PrePatch | Select-String -Pattern " *Start-Process `"wsa:\/\/com\.amazon\.venezia`"");
    If ($_SettingsApp.Matches.Count -ne 0 -or $_ComAndroidSettings.Matches.Count -ne 0 -or $_ComTopJohnWuMagisk.Matches.Count -ne 0 -or $_IoGitHubHuskyDgMagisk.Matches.Count -ne 0 -or $_IoGitHubVvb2060Magisk.Matches.Count -ne 0 -or $_ComAndroidVending.Matches.Count -ne 0 -or $_ComAndroidSettings.Matches.Count -ne 0 -or $_ComAndroidVenezia.Matches.Count -ne 0) {
        Throw "Didn't replace properly!"
    }
    $InstallPs1PrePatch | Out-File -FilePath (Join-Path -Path $script:WSAFolder -ChildPath "Install.ps1")

    Start-Process -Verb RunAs -FilePath "C:\Windows\System32\cmd.exe" -WorkingDirectory $script:WSAFolder -ArgumentList @("/C", "`"$(Join-Path -Path $script:WSAFolder -ChildPath "Run.bat")`"") -ErrorAction Stop -Wait;

    Stop-Service "WSAService" -ErrorAction Stop;

    Pop-Location
    Push-Location $script:TempFolder

    ForEach ($Item in $BackupItems) {
        Copy-Item -Path (Join-Path -Path $script:TempFolder -ChildPath $Item.Name) -Destination (Join-Path -Path $WindowsSubsystemForAndroidDirectory.Fullname -ChildPath "LocalCache" -AdditionalChildPath @($Item.Name)) -ErrorAction Continue;
    }
}
End {
    Pop-Location
    Remove-Item -Recurse $script:TempFolder -ErrorAction Stop;
    Exit-WithCode -Message "Done!";
}
