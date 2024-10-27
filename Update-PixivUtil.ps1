[CmdletBinding()]
Param()

Begin {
  [System.String]$RepositoryOwner = "Nandaka";
  [System.String]$RepositoryName = "PixivUtil2";
  [System.String]$Repository = "$($RepositoryOwner)/$($RepositoryName)";

  [System.String]$Releases = "https://api.github.com/repos/$($Repository)/releases";

  [System.String]$DownloadDest = (Join-Path -Path $env:APROG_DIR -ChildPath ($RepositoryName -replace '\d$', ''));

  . "$(Join-Path -Path (Get-Item -Path $Profile).Directory -ChildPath 'Utils.ps1')";

  [Hashtable]$script:Config = (Get-Config -Path (Join-Path -Path $PSScriptRoot -ChildPath 'config.json'));

  If (-not (Test-Path -LiteralPath $DownloadDest -PathType Container)) {
    If (Test-Path -LiteralPath $DownloadDest -PathType Leaf) {
      Throw "Destination path at $($DownloadDest) is a file not a folder."
    }
    New-Item -Path $DownloadDest -ItemType Directory | Out-Null;
  }

  $FoundTokens = ($script:Config.Tokens | Where-Object {
    Return $Null -ne ($_.Addresses | Where-Object {
      Return $Releases -match $_;
    });
  });

  Remove-Variable -Name "Config" -Scope Script;

  $script:Bearer = $Null;
  If ($Null -ne $FoundTokens) {
    $script:Bearer = (ConvertTo-SecureString -String $FoundTokens.Token -AsPlainText);
  }
} Process {
  Write-Host "Determining latest release...";
  [System.Object[]]$ReleasesData = $null
  [System.Object]  $RepositoryData = $Null;
  [System.String]  $TagName = $Null;

  Try {
    If ($Null -ne $script:Bearer) {
      $ReleasesData = (Invoke-RestMethod -Uri $Releases -UserAgent ([Microsoft.PowerShell.Commands.PSUserAgent]::Chrome) -SkipHttpErrorCheck -Authentication Bearer -Token $script:Bearer);
    } Else {
      $ReleasesData = (Invoke-RestMethod -Uri $Releases -UserAgent ([Microsoft.PowerShell.Commands.PSUserAgent]::Chrome) -SkipHttpErrorCheck -Authentication None);
    }
  } Catch {
    Throw;
  }

  [System.Object]  $RepositoryData = $ReleasesData[0].assets;
  [System.String]  $TagName = $ReleasesData[0].tag_name;

  [System.String[]]$FilesToDownloadApi = @();
  [System.String[]]$FilesToDownload = @();
  [System.String[]]$FileNames = @();

  $RepositoryData | ForEach-Object { $FilesToDownloadApi += $_.url }

  ForEach ($Item in $FilesToDownloadApi) {
    If ($Null -ne $script:Bearer) {
      $Data = (Invoke-RestMethod -Uri "$($Item)" -UserAgent ([Microsoft.PowerShell.Commands.PSUserAgent]::Chrome) -SkipHttpErrorCheck -Authentication Bearer -Token $script:Bearer);
    } Else {
      $Data = (Invoke-RestMethod -Uri "$($Item)" -UserAgent ([Microsoft.PowerShell.Commands.PSUserAgent]::Chrome) -SkipHttpErrorCheck -Authentication None);
    }
    $FilesToDownload += $Data.browser_download_url;
    $FileNames += $Data.name;
  }

  Write-Host "Latest release: $($TagName)";

  Write-Host "Downloading latest release...";

  $OsVersionToDownload = "";

  If ($IsWindows) {
    # TODO: Prompt for Windows (Install), Windows-Portable, Windows-Portable-NoGPU
    $OsVersionToDownload = "windows_.+_gui_gtk_(\d+)";
  } ElseIf ($IsLinux) {
    # TODO: Prompt for Ubuntu, Fedora, AlmaLinux, or ArchLinux
    $OsVersionToDownload = "linux_.+_gui_libraw_heif";
  } ElseIf ($IsMacOS) {
    # TODO: Prompt for macOS, AppImage
    $OsVersionToDownload = "mac_.+_krokiet_heif";
  }

  [string[]]$FilesToDownload = ($FilesToDownload | Where-Object { $_ -match $OsVersionToDownload });
  [string[]]$FileNames = ($FileNames | Where-Object { $_ -match $OsVersionToDownload });

  If ($OsVersionToDownload.EndsWith("(\d+)")) {
    $FilesToDownload = ($FilesToDownload | Select-Object -Property @(@{Name="Name";Expression={$_}},@{Name="Version";Expression={
      $Regex = [System.Text.RegularExpressions.Regex]::Match([System.Text.RegularExpressions.Regex]::Match($_, $OsVersionToDownload, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase).Groups[1].Value, "(\d)(\d+)");
      $Version = [System.Version]::new([System.Int32]::Parse($Regex.Groups[1]), [System.Int32]::Parse($Regex.Groups[2]));
      Return $Version
    }}) | Sort-Object -Property Version | Select-Object -Last 1);
  }

  For ($Index = 0; $Index -lt $FilesToDownload.Length; $Index++) {
    $FileName = $FileNames[$Index];
    $FileNames += $FileName;

    Try {
      If ($Null -ne $script:Bearer) {
        $WebRequest = (Invoke-WebRequest $FilesToDownload[$Index] -SkipHttpErrorCheck -Headers @{ Authentication = "Bearer $($FoundTokens.Token)"} -UserAgent ([Microsoft.PowerShell.Commands.PSUserAgent]::Chrome) -OutFile "$($DownloadDest)\$($FileName)" -PassThru);
      } Else {
        $WebRequest = (Invoke-WebRequest $FilesToDownload[$Index] -SkipHttpErrorCheck -UserAgent ([Microsoft.PowerShell.Commands.PSUserAgent]::Chrome) -OutFile "$($DownloadDest)\$($FileName)" -PassThru);
      }

      If ($WebRequest.StatusCode -ne 200) {
        Throw "Failed to get file at $($FilesToDownload[$Index]) and returned error code $($WebRequest.StatusCode)";
      }
    } Catch {
      Throw;
    }
  }

  Remove-Variable -Name "Bearer" -Scope Script;
  Remove-Variable -Name "FoundTokens";

  [System.String[]]$FilesToKeep = @("Downloads", "config.ini", "config.ini.error-*", "db.sqlite", "cacert.pem", "pixivutil\d+.zip");
  ForEach ($FileName in $FileNames) {
    $FilesToKeep += [System.Text.RegularExpressions.Regex]::Escape($FileName);
  }

  Function Test-MatchFilesToKeep() {
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    Param(
      # Specifies the file to check for.
      [Parameter(Mandatory = $True,
                 Position = 0,
                 HelpMessage = "The file to check for.")]
      [System.String]
      $File,
      # Specifies the list of files to check against.
      [Parameter(Mandatory = $True,
                 Position = 1,
                 HelpMessage = "The list of files to check against.")]
      [System.String[]]
      $FilesToKeep
    )

    Begin {
      [System.Boolean]$Output = $True;
    } Process {
      ForEach ($FileToKeep in $FilesToKeep) {
        [System.Text.RegularExpressions.Regex]$Regex;
        If ($FileToKeep -is [System.String]) {
          $Regex = [System.Text.RegularExpressions.Regex]::new($FileToKeep);
        }
        If ($Null -ne $Regex -and -not $Regex.IsMatch($File)) {
          $Output = $False;
          Break;
        } ElseIf ($Null -eq $Regex) {
          Throw "Type of variable `$Regex is null $($Null -eq $Regex)";
        }
      }
    } End {
      Write-Output -NoEnumerate -InputObject $Output;
    }
  }

  [System.IO.FileSystemInfo[]]$Items = (Get-ChildItem -Path $DownloadDest -Depth 0 -Recurse | Where-Object {
    $Returned = (Test-MatchFilesToKeep -File $_.Name -FilesToKeep $FilesToKeep);
    $Returned = ($Returned | Select-Object -Last 1)
    Write-Output -NoEnumerate -InputObject $Returned;
  });

  ForEach ($Item in $Items) {
    Remove-Item -Force -Recurse -Path $Item.FullName -Verbose;
  }

  If ($FilesToDownload.Length -gt 1) {
    Write-Warning -Message "Downloaded more than one file. Please update the rest manually in $($DownloadDest)";
    Exit 2;
  }

  ForEach ($FileName in $FileNames) {
    Expand-Archive -Force -Path (Join-Path -Path $DownloadDest -ChildPath $FileName) -DestinationPath $DownloadDest;
  }
} End {
} Clean {
  ForEach ($FileName in $FileNames) {
    $FilePath = (Join-Path -Path $DownloadDest -ChildPath $FileName);
    If (Test-Path -LiteralPath $FilePath) {
      Remove-Item -Force -Path $FilePath;
    }
  }
}