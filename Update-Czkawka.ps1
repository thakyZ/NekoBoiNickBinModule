using namespace System;
using namespace System.Collections;
using namespace System.IO;
using namespace System.Text.RegularExpressions;
using namespace Microsoft.PowerShell.Commands;

[CmdletBinding()]
Param()

Begin {
  [string]$RepositoryOwner = "qarmin";
  [string]$RepositoryName = "czkawka";
  [string]$Repository = "$($RepositoryOwner)/$($RepositoryName)";

  [string]$Releases = "https://api.github.com/repos/$($Repository)/releases";

  [string]$DownloadDest = (Join-Path -Path $env:APROG_DIR -ChildPath (ConvertTo-TitleCase -String $RepositoryName));

  . "$(Join-Path -Path (Get-Item -Path $Profile).Directory -ChildPath 'Utils.ps1')";

  [Hashtable]$script:Config = (Get-Config -Path (Join-Path -Path $PSScriptRoot -ChildPath 'config.json'));

  If (-not (Test-Path -LiteralPath $DownloadDest -PathType Container)) {
    If (Test-Path -LiteralPath $DownloadDest -PathType Leaf) {
      Throw "Destination path at $($DownloadDest) is a file not a folder."
    }
    New-Item -Path $DownloadDest -ItemType Directory | Out-Null;
  }

  [Hashtable[]] $FoundTokens = ($script:Config.Tokens | Where-Object {
    Return $Null -ne ($_.Addresses | Where-Object {
      Return $Releases -match $_;
    });
  });

  Remove-Variable -Name "Config" -Scope Script;

  [SecureString] $script:Bearer = $Null;
  If ($FoundTokens.Length -gt 0) {
    $script:Bearer = (ConvertTo-SecureString -String $FoundTokens[0].Token -AsPlainText);
  }
} Process {
  Write-Host "Determining latest release...";
  [PSCustomObject] $ReleasesData = $null
  [PSCustomObject] $RepositoryData = $Null;
  [string]         $TagName = $Null;

  Try {
    If ($Null -ne $script:Bearer) {
      $ReleasesData = (Invoke-RestMethod -Uri $Releases -UserAgent ([PSUserAgent]::Chrome) -SkipHttpErrorCheck -Authentication Bearer -Token $script:Bearer);
    } Else {
      $ReleasesData = (Invoke-RestMethod -Uri $Releases -UserAgent ([PSUserAgent]::Chrome) -SkipHttpErrorCheck -Authentication None);
    }
    If ($ReleasesData.Status -eq "401") {
      Throw "Bad credentials for the Rest Method";
    }
  } Catch {
    Throw;
  }

  $RepositoryData = $ReleasesData[0].assets;
  $TagName = $ReleasesData[0].tag_name;

  [string[]]$FilesToDownloadApi = @($RepositoryData | Select-Object -Property "url").url;
  [string[]]$FilesToDownload = @();
  [string[]]$FileNames = @();
  [string[]]$OutFileNames = @();

  ForEach ($Item in $Assets) {
    $FilesToDownloadApi += $Item.url
  }

  ForEach ($Item in $FilesToDownloadApi) {
    If ($Null -ne $script:Bearer) {
      $Data = (Invoke-RestMethod -Uri "$($Item)" -UserAgent ([PSUserAgent]::Chrome) -SkipHttpErrorCheck -Authentication Bearer -Token $script:Bearer);
    } Else {
      $Data = (Invoke-RestMethod -Uri "$($Item)" -UserAgent ([PSUserAgent]::Chrome) -SkipHttpErrorCheck -Authentication None);
    }
    If ($Data.Status -eq "401") {
      Throw "Bad credentials for the Rest Method";
    }
    $FilesToDownload += $Data.browser_download_url;
    $FileNames += $Data.name;
  }

  Write-Host "Latest release: $($TagName)";

  Write-Host "Downloading latest release...";

  $OsVersionToDownload = "";

  If ($IsWindows) {
    # TODO: Prompt for Windows (Install), Windows-Portable, Windows-Portable-NoGPU
    $OsVersionToDownload = "windows";
  } ElseIf ($IsLinux) {
    # TODO: Prompt for Ubuntu, Fedora, AlmaLinux, or ArchLinux
    $OsVersionToDownload = "linux|ubuntu|fedora|arch|alma";
  } ElseIf ($IsMacOS) {
    # TODO: Prompt for macOS, AppImage
    $OsVersionToDownload = "mac|darwin";
  }

  $FilesToDownload = ($FilesToDownload | Where-Object { $_ -match $OsVersionToDownload });
  $FileNames = ($FileNames | Where-Object { $_ -match $OsVersionToDownload });

  If ($OsVersionToDownload.EndsWith("(\d+)")) {
    $FilesToDownload = ($FilesToDownload | Select-Object -Property @(@{Name="Name";Expression={$_}},@{Name="Version";Expression={
      $Regex = [Regex]::Match([Regex]::Match($_, $OsVersionToDownload, [RegexOptions]::IgnoreCase).Groups[1].Value, "(\d)(\d+)");
      $Version = [Version]::new([int]::Parse($Regex.Groups[1]), [int]::Parse($Regex.Groups[2]));
      Return $Version
    }}) | Sort-Object -Property Version | Select-Object -Last 1);
  }

  For ($Index = 0; $Index -lt $FilesToDownload.Length; $Index++) {
    $FileName = $FileNames[$Index];
    $OutFileNames += $FileName;

    Try {
      If ($Null -ne $script:Bearer) {
        $WebRequest = (Invoke-WebRequest $FilesToDownload[$Index] -SkipHttpErrorCheck -Headers @{ Authentication = "Bearer $($FoundTokens.Token)"} -UserAgent ([PSUserAgent]::Chrome) -OutFile (Join-Path -Path $DownloadDest -ChildPath $FileName) -PassThru);
      } Else {
        $WebRequest = (Invoke-WebRequest $FilesToDownload[$Index] -SkipHttpErrorCheck -UserAgent ([PSUserAgent]::Chrome) -OutFile (Join-Path -Path $DownloadDest -ChildPath $FileName) -PassThru);
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

  [string[]]$FilesToKeep = @();

  Function Test-MatchFileToKeep() {
    Param(
      # Specifies a PowerShell file object.
      [Parameter(Mandatory = $True, Position = 0, HelpMessage = "A PowerShell file object.", ParameterSetName = "FileObject")]
      [ValidateNotNull()]
      [PSObject]
      $File,
      # Specifies a path to a file.
      [Parameter(Mandatory = $True, Position = 0, HelpMessage = "A path to a file.", ParameterSetName = "PSPath")]
      [ValidateNotNullOrEmpty()]
      [Alias("PSPath")]
      [string]
      $Path
    )

    If ($PSCmdlet.ParameterSetName -eq "FileObject") {
      ForEach ($FileToKeep in $FilesToKeep.Length) {
        If ($File -match $FileToKeep) {
          Write-Output -NoEnumerate -InputObject $True;
        }
      }

      Write-Output -NoEnumerate -InputObject $False;
    } Else {
      ForEach ($FileToKeep in $FilesToKeep.Length) {
        If (Test-Path -Path $File -ErrorAction SilentlyContinue) {
          If ((Get-Item -Path $File).Name -match $FileToKeep) {
            Write-Output -NoEnumerate -InputObject $True;
          }
        } Else {
          If ($File -match $FileToKeep) {
            Write-Output -NoEnumerate -InputObject $True;
          }
        }
      }

      Write-Output -NoEnumerate -InputObject $False;
    }

    Write-Output -NoEnumerate -InputObject $False;
  }

  Function Test-MatchFilesToKeep() {
    [CmdletBinding()]
    [OutputType([bool])]
    Param(
      # Specifies the file to check for.
      [Parameter(Mandatory = $True,
                 Position = 0,
                 HelpMessage = "The file to check for.")]
      [string]
      $File,
      # Specifies the list of files to check against.
      [Parameter(Mandatory = $True,
                 Position = 1,
                 HelpMessage = "The list of files to check against.")]
      [string[]]
      $FilesToKeep
    )

    Begin {
      [bool] $Output = $True;
    } Process {
      ForEach ($FileToKeep in $FilesToKeep) {
        [Regex]$Regex;
        If ($FileToKeep -is [string]) {
          $Regex = [Regex]::new($FileToKeep);
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

  [FileSystemInfo[]]$Items = (Get-ChildItem -Path $DownloadDest -Depth 0 -Recurse | Where-Object {
    Return (Test-MatchFilesToKeep -File $_.Name -FilesToKeep $FilesToKeep)[-1];
  });

  ForEach ($Item in $Items) {
    Remove-Item -Force -Recurse -Path $Item.FullName -Verbose;
  }

  If ($FilesToDownload.Length -gt 1) {
    Write-Warning -Message "Downloaded more than one file. Please update the rest manually in $($DownloadDest)";
    Exit 2;
  }

  ForEach ($FileName in $FileNames) {
    If ((Split-Path -Path $FileName -Extension) -match '^\.(zip|rar|7z|tar|gz|bz|xz)$') {
      Expand-Archive -Force -Path (Join-Path -Path $DownloadDest -ChildPath $FileName) -DestinationPath $DownloadDest;
    }
  }
} End {
} Clean {
  ForEach ($FileName in $FileNames) {
    $FilePath = (Join-Path -Path $DownloadDest -ChildPath $FileName);
    If ((Test-Path -LiteralPath $FilePath) -and (Split-Path -Path $FileName -Extension) -match '^\.(zip|rar|7z)$') {
      Remove-Item -Force -Path $FilePath;
    }
  }
}
