Param(
  # Specifies the version to download of VLC.
  [Parameter(Mandatory = $False,
             Position = 0,
             HelpMessage = "The version to download of VLC.")]
  [String]
  $Version,
  # Specifies the switch to download VLC Nightly.
  [Parameter(Mandatory = $False,
             Position = 1,
             HelpMessage = "Tthe switch to download VLC Nightly.")]
  [Switch]
  $Nightly
)

$UserAgent = 'Mozilla/5.0 (X11; Fedora; Linux x86_64; rv:52.0) Gecko/20100101 Firefox/52.0';

$DownloadUri = "aHR0cHM6Ly9hcnRpZmFjdHMudmlkZW9sYW4ub3JnL3ZsYy9uaWdodGx5LXdpbjY0LWxsdm0v";

$DownloadUri = (ConvertFrom-Base64 -Base64 $DownloadUri -ToString);

$InstallPath = (Join-Path -Path "C:\" -ChildPath "Progra~1" -AdditionalChildPath @("VideoLAN", "VLC"));
$DownloadPath = (Join-Path -Path $env:TEMP -ChildPath "Update-VLC");
$ExtractPath = $DownloadPath;

$ExcludePaths = @();
$Items = (Get-ChildItem -LiteralPath $InstallPath -ErrorAction SilentlyContinue -Exclude $ExcludePaths);
$Progress = 0;
$Percent = 0;

Function Write-HostOverLine() {
  Param(
    # The Object to write over the original line.
    [Parameter(Position = 0, Mandatory = $True)]
    [Object]
    $Object,
    # Foreground color to write the line with
    [Parameter(Position = 0, Mandatory = $False)]
    [ValidateSet("Black", "Blue", "Cyan", "DarkBlue", "DarkCyan", "DarkGray", "DarkGreen", "DarkMagenta", "DarkRed", "DarkYellow", "Gray", "Green", "Magenta", "Red", "White", "Yellow")]
    [string]
    $ForegroundColor = "Yellow"
  )

  $CursorLeft = [System.Console]::CursorLeft;
  $CursorTop = [System.Console]::CursorTop;
  Write-Host -Object $Object -ForegroundColor $ForegroundColor;
  [System.Console]::CursorLeft = $CursorLeft;
  [System.Console]::CursorTop = $CursorTop;
}

$Progress = 0;

If (-not (Test-Path -LiteralPath $DownloadPath -PathType Container)) {
  New-Item -Path $DownloadPath -ItemType Directory -ErrorAction SilentlyContinue | Out-Null;
}

Function Get-DownloadFile() {
  Param(
    # Specifies the uri of the download page.
    [Parameter(Mandatory = $True, Position = 0, HelpMessage = "Uri of the download page.")]
    [string]
    $Uri,
    # Specifies the position in the list to download.
    [Parameter(Mandatory = $False, Position = 1, HelpMessage = "Position in the list to download.")]
    [int]
    $DownloadIndex = 0
  )

  $Web = $Null;
  $DownloadFile = $Null;
  $DownloadDomain = $Null;
  $_DownloadPath = $DownloadPath;
  $NewUri = $Null;
  $Web2 = $Null;
  Try {
    $Web1 = (Invoke-WebRequest -UserAgent $UserAgent -Uri $Uri);
    $Index = -1;
    $FoundVersion = $Web1.Links | Where-Object {
      $Index++;
      If ($_.href -ne "../") {
        If (-not ([System.String]::IsNullOrEmpty($Version)) -and $_.href -eq "$($Version)/") {
          Return $True;
        } ElseIf (([System.String]::IsNullOrEmpty($Version)) -and $Index -eq 1) {
          Return $True;
        }
      }
      Return $False;
    };

    If ($FoundVersion.Count -gt 1) {
      Throw "Too many results found $($FoundVersion.Count).";
    } ElseIf ($FoundVersion.Count -eq 0) {
      Throw "No results found $($FoundVersion.Count).";
    }

    $Web2 = (Invoke-WebRequest -UserAgent $UserAgent -Uri "$($Uri)$($FoundVersion.href)");
    $FoundHash = $Web2.Links | Where-Object {
      If ($_.href -ne "../" -and $_.href -match ".*SUM") {
        Return $True;
      }

      Return $False;
    };

    If ($FoundHash.Count -gt 1) {
      Throw "Too many results found $($FoundHash.Count).";
    } ElseIf ($FoundHash.Count -eq 0) {
      Throw "No results found $($FoundHash.Count).";
    } Else {
      $DownloadHashFile = "$($Uri)$($FoundVersion.href)$($FoundHash.href)"
    }

    $FoundMsi = $Web2.Links | Where-Object {
      If ($_.href -ne "../" -and $_.href -match ".*\.msi") {
        Return $True;
      }

      Return $False;
    };

    If ($FoundMsi.Count -gt 1) {
      Throw "Too many results found $($FoundVersion.Count).";
    } ElseIf ($FoundMsi.Count -eq 0) {
      Throw "No results found $($FoundVersion.Count).";
    } Else {
      $DownloadMsiFile = "$($Uri)$($FoundVersion.href)$($FoundMsi.href)"
    }

    $Accept = "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/jxl,image/webp,*/*;q=0.8"; # "application/octet-stream";
    $AcceptEncoding = "gzip, deflate, br"; # "binary";

    $_DownloadPathHash = (Join-Path -Path $DownloadPath -ChildPath $FoundHash.href);
    $_DownloadPathMsi  = (Join-Path -Path $DownloadPath -ChildPath $FoundMsi.href);
    $Web3 = (Invoke-WebRequest -UserAgent $UserAgent -Uri $DownloadHashFile -PassThru -OutFile $_DownloadPathHash -Headers @{ Accept = $Accept; "Accept-Encoding" = $AcceptEncoding });
    $Web4 = (Invoke-WebRequest -UserAgent $UserAgent -Uri $DownloadMsiFile  -PassThru -OutFile $_DownloadPathMsi  -Headers @{ Accept = $Accept; "Accept-Encoding" = $AcceptEncoding });
  } Catch {
    Write-Error -Exception $_.Exception -Message $_.Exception.Message | Out-Host;
    Write-Output @{ Error = $True; Arguments = @($Uri, $DownloadIndex); WebFetch = @($Web, $Web2); DownloadFile = (Get-Item -Path $_DownloadPath -ErrorAction SilentlyContinue); DownloadDomain = $DownloadDomain; NewUri = $NewUri; WebDownload = @($Web3, $Web4) };
    Throw;
  }
  Return @{ Error = $False; Arguments = @($Uri, $DownloadIndex); WebFetch = @($Web, $Web2); DownloadFile = @((Get-Item -Path $_DownloadPathHash -ErrorAction SilentlyContinue), (Get-Item -Path $_DownloadPathMsi -ErrorAction SilentlyContinue)); DownloadDomain = $DownloadDomain; NewUri = $NewUri; WebDownload = @($Web3, $Web4) };
}

$Web = (Get-DownloadFile -Uri $DownloadUri);

If ($Web.Error -eq $True) {
  Write-Output $Web;
  Exit 1;
}

$DownloadFileHash = $Web.DownloadFile[0];
$DownloadFileMsi = $Web.DownloadFile[1];

Try {
  If ($DownloadFileMsi.Extension -eq ".msi" -and $DownloadFileHash.Extension -eq "") {
      $Hash = (Get-FileHash -Path $DownloadFileMsi.FullName -Algorithm SHA512);
      $HashFileContent = (Get-Content -Path $DownloadFileHash.FullName);
      $Hashes = @()
      ForEach ($Line in ($HashFileContent -Split "`n")) {
        $Item=($Line -Split "  ");
        $TempItem = @{ Name = $Item[1]; Hash = $Item[0] };
        $Items += $TempItem;
      };
      $FoundFile = ($Hashes | Where-Object { $_.Name -eq "./$($DownloadFileMsi.Name)" });
      If ($Null -ne $FoundFile -and $Hash.Hash.ToLower() -eq $FoundFile.Hash) {
        
      }
  } Else {
    Write-Error -Message "Download file was not the expected extension `".msi`" and `"`$Null`" please contact the author of this script.";
    Exit 1;
  }

  Remove-Item -LiteralPath $DownloadFile -ErrorAction Stop;

  $ExtractedDir = (Get-ChildItem -LiteralPath $ExtractPath -Directory);

  If ($ExtractedDir.Length -eq 0) {
    Write-Error -Message "Did not find extracted directory, please contact the author of this script..";
    Exit 1;
  }

  $Items = (Get-ChildItem -LiteralPath $ExtractedDir[0]);

  ForEach ($Item in $Items) {
    $Percent = "$([Math]::Ceiling(($Progress / $Items.Length) * 100))%";
    Write-HostOverLine -Object "Removing old files... $($Percent) - $($Progress) / $($Items.Length)"
    Move-Item -Path $Item.FullName -Destination $InstallPath -ErrorAction Stop;
    $Progress++;
  }
  Remove-Item -LiteralPath $DownloadPath -Recurse -ErrorAction Stop;

} Catch {
  Write-Error -Exception $_.Exception -Message $_.Exception.Message;
  Write-Output $Web;
  Exit 1;
}