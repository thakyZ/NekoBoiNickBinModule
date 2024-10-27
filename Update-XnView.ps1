[CmdletBinding()]
Param()

Begin {
  Function Get-CurrentVersion {
    [CmdletBinding()]
    [OutputType([System.Version])]
    Param(
      # Specifies the directory that the program is installed into.
      [Parameter(Mandatory = $True,
                 HelpMessage = "The directory that the program is installed into.")]
      [System.String]
      $InstallDir
    )

    Begin {
      [System.Version]$Output = $Null;
      $SettingsFile = (Get-Item -LiteralPath (Join-Path -Path $InstallDir -ChildPath "xnview.ini"));
      Try {
        Add-Type -Path (Join-Path -Path $PSScriptRoot -ChildPath "APROG_DIR.dll");
      } Catch {
        Write-Error -ErrorRecord $_;
      }
      Try {
        $IniFile = [NekoBoiNick.CSharp.PowerShell.Cmdlets.IniParser]::ParseFileToHashtable("$($SettingsFile)");
      } Catch {
        Write-Error -ErrorRecord $_;
        If ($Null -ne $_.Exception.InnerException) {
          Write-Host -Object $_.Exception.InnerException.StackTrace;
        }
        Throw;
      }
    }
    Process {
      $Output = [System.Version]::new([System.Text.Encoding]::UTF8.GetString($IniFile["%General"]["version"]));
    }
    End {
      Write-Output -NoEnumerate -InputObject $Output;
    }
  }
  $UrlToFetchFrom = (ConvertFrom-Base64 -ToString -Base64 "aHR0cHM6Ly93d3cueG52aWV3LmNvbS9lbi94bnZpZXdtcC8=");
}
Process {
  Write-Host "Determining latest release..."

  $InstallDir = (Get-Item -LiteralPath (Join-Path -Path $env:APROG_DIR -ChildPath "XnViewMP"));
  [Microsoft.PowerShell.Commands.WebResponseObject]$Website = $Null

  Try {
    $Website = (Invoke-WebRequest -Uri $UrlToFetchFrom -SkipHttpErrorCheck -ErrorAction "SilentlyContinue" -UserAgent ([Microsoft.PowerShell.Commands.PSUserAgent]::Chrome));

    If ($Website.StatusCode -ne 200) {
      Throw [Microsoft.PowerShell.Commands.HttpResponseException]::new("Failed to get url `"$($UrlToFetchFrom)`" got status code $($Website.StatusCode)");
    }
  } Catch {
    Write-Error -ErrorRecord $_;
    Exit 1;
  }

  [Microsoft.PowerShell.Commands.WebResponseObject]$Download = $Null

  If ($Null -ne $Website) {
    Try {
      $LatestVersion = [System.Version]::new()
      $CurrentVersion = (Get-CurrentVersion -InstallDir $InstallDir)
      $Regex = [System.Text.RegularExpressions.Regex]::new('<p class="h5 mt-3">Download <strong>XnView MP (\d+\.\d+(?:\.\d+))</strong>:</p>')
      If (-not $Regex.IsMatch($WebSite.Content)) {
        Write-Host -ForegroundColor White      -Object "[" -NoNewLine;
        Write-Host -ForegroundColor DarkYellow -Object "WRN" -NoNewLine;
        Write-Host -ForegroundColor White      -Object "] " -NoNewLine;
        Write-Host -ForegroundColor DarkYellow -Object "Failed to determine latest version. Regex.IsMatch = False";
      } Else {
        $_Matches = $Regex.Match($WebSite.Content)
        $Groups = $_Matches.Groups
        If ($Groups.Count -ne 2) {
          Write-Host -ForegroundColor White      -Object "[" -NoNewLine;
          Write-Host -ForegroundColor DarkYellow -Object "WRN" -NoNewLine;
          Write-Host -ForegroundColor White      -Object "] " -NoNewLine;
          Write-Host -ForegroundColor DarkYellow -Object "Failed to determine latest version. Groups.Count = $($Groups.Count)";
          If ($Groups.Count -gt 2 -and $DebugPreference -ne "SilentlyContinue") {
            ForEach ($Group in $Groups) {
              Write-Host -ForegroundColor White      -Object "[" -NoNewLine;
              Write-Host -ForegroundColor DarkBlue   -Object "DBG" -NoNewLine;
              Write-Host -ForegroundColor White      -Object "] " -NoNewLine;
              Write-Host -ForegroundColor Gray       -Object "$($Group.Value)";
            }
          }
        } Else {
          [System.String]$VersionString = $Groups[1].Value;
          $LatestVersion = [System.Version]::new($VersionString);
        }
      }

      If ($CurrentVersion -ge $LatestVersion) {
        Write-Host -ForegroundColor White    -Object "[" -NoNewLine;
        Write-Host -ForegroundColor DarkBlue -Object "INF" -NoNewLine;
        Write-Host -ForegroundColor White    -Object "] " -NoNewLine;
        Write-Host -ForegroundColor White    -Object "Current version is greater or equal to latest version ($CurrentVersion >= $LatestVersion)" -NoNewLine;
        Exit 0;
      }

      [System.String]$DownloadLink = $Null;
      [System.String]$FileName = "XnViewMP.zip";

      If ($IsWindows -and (Get-SystemArchitecture) -eq "x64") {
        $DownloadLink = ($Website.Links.href | Where-Object { $_ -match "-win-x64\.zip$" });
        $FileName = "XnViewMP-x64.zip";
      } ElseIf ($IsWindows) {
        $DownloadLink = ($Website.Links.href | Where-Object { $_ -match "-win\.zip$" });
      } ElseIf ($IsLinux) {
        $DownloadLink = ($Website.Links.href | Where-Object { $_ -match "-linux\.tgz$" });
        $FileName = "XnViewMP.tgz";
      } ElseIf ($IsMacOS) {
        $DownloadLink = ($Website.Links.href | Where-Object { $_ -match "-mac\.dmg$" });
        $FileName = "XnViewMP.dmg";
      } Else {
        Throw "Your OS is not supported by this application."
      }

      Try {
        $Download = (Invoke-WebRequest -Uri $DownloadLink -SkipHttpErrorCheck -ErrorAction SilentlyContinue -UserAgent ([Microsoft.PowerShell.Commands.PSUserAgent]::Chrome) -OutFile (Join-Path -Path $InstallDir -ChildPath $FileName) -PassThru);

        If ($Download.StatusCode -ne "200") {
          Throw [Microsoft.PowerShell.Commands.HttpResponseException]::new("Failed to get url `"$($DownloadLink)`" got status code $($Download.StatusCode)");
        } Else {
          If ($IsWindows) {
            Push-Location $InstallDir;
            Expand-Archive -Path (Join-Path -Path $InstallDir -ChildPath $FileName) -Force -DestinationPath $InstallDir;
            Move-ItemRecurse -Path (Join-Path -Path $InstallDir -ChildPath $InstallDir.Name) -Destination $InstallDir -Force;
            Remove-Item -Path (Join-Path -Path $InstallDir -ChildPath $FileName);
            Pop-Location;
          } Else {
            Throw "Your OS is not supported by this script (yet)."
          }
        }
      } Catch {
        Write-Error -ErrorRecord $_;
        Exit 1;
      }
    } Catch {
      Write-Error -ErrorRecord $_;
      Exit 1;
    }
  } Else {
    Exit 1;
  }
}
End {
} Clean {
  Remove-Item -Path (Join-Path -Path $PSScriptRoot -ChildPath "Extensions.dll") -ErrorAction SilentlyContinue;
  Remove-Item -Path (Join-Path -Path $PSScriptRoot -ChildPath "IniParser.dll") -ErrorAction SilentlyContinue;
  Pop-Location
}
