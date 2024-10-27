[CmdletBinding()]
Param()

# cSpell:word vhdx, Magisk, Gapps,
# cSpell:ignoreRegExp /WindowsSubsystemForAndroid_[\d\w]+/
# cSpell:ignoreRegExp /(?<=wsa:\\\/\\\/com\\\.)topjohnwu(?=\\\.magisk)/
# cSpell:ignoreRegExp /(?<=wsa:\\\/\\\/io\\\.github\\\.)huskydg(?=\\\.magisk)/

Begin {
  . "$(Join-Path -Path $PSScriptRoot -ChildPath "Exit-WithCode.ps1")";
  . "$((Join-Path -Path (Get-Item -Path $Profile).Directory -ChildPath "Utils.ps1"))";

  [System.Object] $script:Config = (Get-Config -Path (Join-Path -Path $PSScriptRoot -ChildPath "config.json"));
  [System.Boolean]$script:UseToken = $True;
  [System.String] $script:Token = $script:Config.Tokens.Where({ $_.Addresses -contains "github.com" });

  If ($script:Token.Count -ne 0) {
    $script:UseToken = $False;
  }

  Remove-Variable -Scope Script -Name "Config";
  Function Write-Header {
    Write-Host -ForegroundColor Red "#############################################################################################################";
    Write-Host -ForegroundColor Red "#                                                                                                           #";
    Write-Host -ForegroundColor Red "# " -NoNewline;
    Write-Host -ForegroundColor White "Be sure to backup your save file!!!" -NoNewline;
    Write-Host -ForegroundColor Red "                                                                       #";
    Write-Host -ForegroundColor Red "#                                                                                                           #";
    Write-Host -ForegroundColor Red "#############################################################################################################";
    Write-Host -ForegroundColor Green "https://github.com/MustardChef/WSABuilds/blob/master/Documentation/WSABuilds/Backup%20and%20Restore.md";
    $Confirm = (Read-Host -Prompt "Continue (Y/N)")
    If ($Confirm -match "[Yy](?:[Ee][Ss])?") {
      Write-Output -NoEnumerate -InputObject $True;
    }
    Write-Output -NoEnumerate -InputObject $False;
  }
  $script:TempFolder = (Join-Path -Path $HOME -ChildPath ".WSA_backup");
  If (Test-Path -LiteralPath $script:TempFolder -PathType Container) {
    Remove-Item -Recurse $script:TempFolder -ErrorAction Stop;
  }
  New-Item -Path $script:TempFolder -ItemType Directory -ErrorAction Stop | Out-Null;
  $script:LocationStackName = "UpdateWSA"
  Push-Location -LiteralPath $script:TempFolder -StackName $script:LocationStackName;
  Stop-Service "WSAService" -ErrorAction SilentlyContinue;
}
Process {
  Function Start-SelectionDialog {
    [CmdletBinding()]
    [OutputType([System.String])]
    Param(
      # Specifies the list of releases from GitHub API.
      [Parameter(Mandatory = $True,
        Position = 0,
        HelpMessage = "The list of releases from GitHub API.")]
      [System.Object[]]
      $ListOfReleases
    )

    [System.String]$Output = $Null;

    If ($Null -eq (Get-Command -Name "Get-SystemArchitecture" -ErrorAction SilentlyContinue)) {
      Throw "PowerShell command `"Get-SystemArchitecture`" was not found on the path.";
    }

    If ($Null -eq (Get-Command -Name "Get-ConsolePosition" -ErrorAction SilentlyContinue)) {
      Throw "PowerShell command `"Get-ConsolePosition`" was not found on the path.";
    }

    If ($Null -eq (Get-Command -Name "Clear-ConsoleInArea" -ErrorAction SilentlyContinue)) {
      Throw "PowerShell command `"Clear-ConsoleInArea`" was not found on the path.";
    }

    If ((Get-ComputerInfo | Select-Object -Expand "OsName") -match 11) {
      $local:Finished = $False;

      While ($local:Finished -eq $False) {
        [PSCustomObject]$StartingPosition = (Get-ConsolePosition);

        Try {
          [System.String]$Architecture = (Get-SystemArchitecture);
          [System.Object[]]$Assets = $Latest.Where({ $_.name.Contains("Windows 11 $($Architecture)") })[0].assets;

          [System.Int32]$Index = 0;

          ForEach ($Item in $Assets) {
            Write-Host -Object "[$($Index)] $($Item.name)"
            $Index++;
          }

          [System.String]$PromptInput = (Read-Host -Prompt "[0-$($Index - 1)]");
          [System.Int32]$Parsed = [System.Int32]::Parse($PromptInput);

          If ($Parsed -ge 0 -and $Parsed -lt $Index) {
            $Output = $Assets[$Parsed].browser_download_url;
            Clear-ConsoleInArea -Start $StartingPosition -End (Get-ConsolePosition);
            $local:Finished = $True;
          } Else {
            Throw "Input value was greater or less than the allowed amount.";
          }
        } Catch {
          Write-Error -Message $_.Exception.Message;
          Start-Sleep -Seconds 5;
          Clear-ConsoleInArea -Start $StartingPosition -End (Get-ConsolePosition);
        }
      }

      Remove-Variable -Scope Local -Name "Finished";
    } Else {
      Throw "Must be ran on a Windows 11 computer."
    }

    Write-Output -NoEnumerate -InputObject $Output;
  }

  If (-not (Write-Header)) {
    Exit-WithCode -Message "" -Code 0 -PopLocation $script:LocationStackName -CleanAllVariables;
  }

  $WindowsSubsystemForAndroidDirectory = ((Get-ChildItem -Path (Join-Path -Path $env:LocalAppData -ChildPath "Packages") -Directory) | Where-Object { $_.BaseName -match ".*\.WindowsSubsystemForAndroid_.*" });

  If ($WindowsSubsystemForAndroidDirectory.Count -gt 1) {
    Exit-WithCode -Message "Too many Windows Subsystem For Android Directories found in `"$(Join-Path -Path $env:LocalAppData -ChildPath "Packages")`"..." -Throw -CleanAllVariables;
  }

  $BackupItems = (Get-ChildItem -Path (Join-Path -Path $WindowsSubsystemForAndroidDirectory.FullName -ChildPath "LocalCache") -File -Filter "*.vhdx");

  ForEach ($Item in $BackupItems) {
    [System.String]$Destination = (Join-Path -Path $script:TempFolder -ChildPath $Item.Name);
    Write-Host -Object "Copying `"$(Get-SimplePath -Path $Item.FullName -RelativeBasePath $WindowsSubsystemForAndroidDirectory.FullName -ReplaceWith "%WSA%")`" to `"$(Get-SimplePath -Path $Destination -RelativeBasePath $HOME -ReplaceWith "%HOME%")`""
    Copy-Item -Path $Item.FullName -Destination $Destination -ErrorAction Stop;
  }

  Try {
    [System.String]$RestCommand = "Invoke-RestMethod -Uri `"https://api.github.com/repos/MustardChef/WSABuilds/releases`" -UserAgent ([Microsoft.PowerShell.Commands.PSUserAgent]::Chrome)";
    If ($script:UseToken) {
      $RestCommand += " -Authentication Bearer -Token $($script:Token)";
    }
    $Latest = (Invoke-Expression -Command $RestCommand);

    If ($Null -eq $Latest) {
      Throw "Failed to find latest releases.";
    } ElseIf (($Latest | Get-Member).Name.Contains("message")) {
      Throw "$($Latest.message)";
    }

    [System.String]$DownloadUri = (Start-SelectionDialog -ListOfReleases $Latest);

    If ($Null -eq $DownloadUri) {
      Throw "Failed to find download uri."
    }

    $Headers = @{};

    If ($script:UseToken) {
      $Headers["Authentication"] = "Bearer $($script:Token)";
    }

    $DownloadFile = (Invoke-WebRequest -Uri $DownloadUri -Headers $Headers -ErrorAction Stop -SkipHttpErrorCheck -PassThru -OutFile (Join-Path -Path $script:TempFolder -ChildPath "wsa.7z"))

    If ($DownloadFile.StatusCode -ne 200) {
      Throw "The attempted download of a file at uri `"$($DownloadUri)`" returned status code $($DownloadFile.StatusCode) and description `"$($DownloadFile.StatusDescription)`"."
    }
  } Catch {
    Exit-WithCode -InputObject $_ -PopLocation $script:LocationStackName -Code 1 -CleanAllVariables | Out-Host;
  }

  & "$(Get-Command -Name "7z" -ErrorAction Stop)" x "$(Join-Path -Path $script:TempFolder -ChildPath "wsa.7z")"

  $script:WSAFolder = (Get-ChildItem -Path $script:TempFolder -Directory | Where-Object { $_.Name.StartsWith("WSA_") });

  Stop-Service "WSAService" -ErrorAction Stop;

  Start-Process -Verb RunAs -FilePath (Get-Command -Name "powershell").Source -WorkingDirectory $script:WSAFolder -ArgumentList @("-Command", "Get-AppxPackage `"[I]MicrosoftCorporationII.WindowsSubsystemForAndroid[/I]`" | Remove-AppxPackage;Get-ChildItem -ErrorAction Stop -Path `"C:\WSA`" | ForEach-Object { Remove-Item -Recurse -Force -ErrorAction Stop -Path `$_.FullName };Get-ChildItem -ErrorAction Stop -Path `"$($script:WSAFolder)`" | ForEach-Object { Move-Item -Force -ErrorAction Stop -Path `$_.FullName -Destination (Join-Path -Path `"C:\WSA`" -ChildPath `"`$_.Name`") };") -ErrorAction Stop -Wait;

  $script:WSAFolder = "C:\WSA"

  Pop-Location -StackName $script:LocationStackName
  Push-Location -LiteralPath $script:WSAFolder -StackName $script:LocationStackName

  Write-Host -Object "Replacing:"
  $InstallPs1PrePatch = (Get-Content -Path (Get-Item -Path (Join-Path -Path $script:WSAFolder -ChildPath "Install.ps1")) -Raw);
  $_StartProcessesMatches = ($InstallPs1PrePatch | Select-String -Pattern " *Start-Process `"(?:shell:AppsFolder\\.+|wsa:\/\/.+)`"");
  If ($_StartProcessesMatches.Matches.Count -gt 0) {
    ForEach ($Match in $_StartProcessesMatches.Matches) {
      Write-Host -Object $Match.Value;
      $InstallPs1PrePatch = ($InstallPs1PrePatch -Replace " *Start-Process `"(?:shell:AppsFolder\\.+|wsa:\/\/.+)`"", "");
    }
  }
  $_StartProcessesMatchesAfter = ($InstallPs1PrePatch | Select-String -Pattern " *Start-Process `"(?:shell:AppsFolder\\.+|wsa:\/\/.+)`"");
  If ($_StartProcessesMatchesAfter.Matches.Count -ne 0) {
    Write-Warning -Message "Didn't replace properly!";
    Write-Host -Object "Press any key to continue...";
    Pause;
  }
  Write-Host -Object "Finished"
  $InstallPs1PrePatch | Out-File -FilePath (Join-Path -Path $script:WSAFolder -ChildPath "Install.ps1")

  Start-Process -Verb RunAs -FilePath "C:\Windows\System32\cmd.exe" -WorkingDirectory $script:WSAFolder -ArgumentList @("/C", "`"$(Join-Path -Path $script:WSAFolder -ChildPath "Run.bat")`"") -ErrorAction Stop -Wait;

  Stop-Service "WSAService" -ErrorAction Stop;

  Pop-Location -StackName $script:LocationStackName
  Push-Location -LiteralPath $script:TempFolder -StackName $script:LocationStackName

  ForEach ($Item in $BackupItems) {
    Copy-Item -Path (Join-Path -Path $script:TempFolder -ChildPath $Item.Name) -Destination (Join-Path -Path $WindowsSubsystemForAndroidDirectory.Fullname -ChildPath "LocalCache" -AdditionalChildPath @($Item.Name)) -ErrorAction Continue;
  }
}
End {
  Pop-Location -StackName $script:LocationStackName
  Remove-Item -Recurse $script:TempFolder -ErrorAction Stop;
  Exit-WithCode -Message "Done!" -PopLocation $script:LocationStackName -CleanAllVariables;
}
