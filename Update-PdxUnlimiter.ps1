Param()

. "$((Join-Path -Path (Get-Item -Path $Profile).Directory -ChildPath "Utils.ps1"))";

$script:Config = (Get-Config -Path (Join-Path -Path $PSScriptRoot -ChildPath "config.json"));

$Repo = "crschnick/pdx_unlimiter"

$Releases = "https://api.github.com/repos/$($Repo)/releases"

$DownloadDest = "D:\Modding\Tools\Stellaris\PDX-Unlimiter"

Write-Host "Determining latest release..."

Function Invoke-NewWebRequest() {
  Param(
    # Parameter help description
    [Parameter(Mandatory = $True)]
    [ValidateNotNullOrEmpty()]
    [string]
    $Uri,
    # Parameter help description
    [Parameter(Mandatory = $False,
      ParameterSetName = "OutFile")]
    [ValidateNotNullOrEmpty()]
    [string]
    $Out
  )


  $WebRequestData = "(Invoke-WebRequest `"$($Uri)`"";

  $FoundTokens = ($script:Config.Tokens | Where-Object {
      $Obj1 = $_;
      Return $Null -ne ($obj1.Addresses | Where-Object {
          $Obj2 = $_;
          Return $Releases -match $Obj2;
        });
    });

  If ($Null -ne $FoundTokens) {
    $WebRequestDataHeader = " -Headers @{ Authorization = `"Bearer $($FoundTokens.Token)`" }";
    $WebRequestData += $WebRequestDataHeader;
  }

  If ($PSCmdlet.ParameterSetName -eq "OutFile") {
    $WebRequestData += "-Out `"$($Out)`"";
  }

  $WebRequestData += " | ConvertFrom-Json)";

  Try {
    $Response = (Invoke-Expression -Command $WebRequestData);
  } Catch {
    Write-Error -Exception $_.Exception -Message $_.Exception.Message;
    Throw $_.Exception;
  }

  Return $Response;
}

$WebRequestResponse = (Invoke-NewWebRequest -Uri $Releases);

$RepoData = $WebRequestResponse[0].assets;
$TagName = $WebRequestResponse[0].tag_name;

$FilesToDownloadApi = @()
$FilesToDownload = @()

ForEach ($Item in $RepoData) {
  $FilesToDownloadApi += $Item.url
}

ForEach ($Item in $FilesToDownloadApi) {
  $Data = (Invoke-NewWebRequest -Uri $Item)
  $FilesToDownload += $Data
}

Write-Host "Latest release: $($TagName)";

Write-Host "Dowloading latest release..."

$OsVersionToDownload = "";
$OsProcessorToDownload = "";

If ($IsWindows) {
  $OsVersionToDownload = "windows";
  #$OsProcessorToDownload = "$Env:PROCESSOR_ARCHITECTURE";
} Else {
  #$OsProcessorToDownload = (& "$((Get-Commaand -Name "uname" -ErrorAction Stop).Source)" -p);

  If ($IsLinux) {
    $OsVersionToDownload = "linux";
  } ElseIf ($IsMacOS) {
    $OsVersionToDownload = "macos";
    $OsProcessorToDownload = (& "$((Get-Commaand -Name "uname" -ErrorAction Stop).Source)" -p);
  }
}

$FilesToDownloadFiltered = ($FilesToDownload | Where-Object {
    If ($_ -match ".*$($OsVersionToDownload ).*") {
      If (-not [string]::IsNullOrEmpty($OsProcessorToDownload)) {
        If ($_ -match ".*$($OsProcessorToDownload).*") {
          Return $True;
        }
      } Else {
        Return $True;
      }
    }
    Return $False;
  });

ForEach ($FileToDownload in $FilesToDownloadFiltered) {
  $FileName = $FileToDownload.name
  Invoke-NewWebRequest -Uri $FileToDownload.browser_download_url -Out (Join-Path -Path $DownloadDest -ChildPath $FileName)
}

$FilesToKeep = @()

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
      If ($File -notmatch $FileToKeep) {
        Return $True;
      }
    }

    Return $False;
  } Else {
    ForEach ($FileToKeep in $FilesToKeep.Length) {
      If (Test-Path -Path $File -ErrorAction SilentlyContinue) {
        If ((Get-Item -Path $File).Name -notmatch $FileToKeep) {
          Return $True;
        }
      } Else {
        If ($File -notmatch $FileToKeep) {
          Return $True;
        }
      }
    }

    Return $False;
  }

  Return $False;
}

Function Test-MatchFilesToKeep() {
  param(
    # Specifies an array of PowerShell file object.
    [Parameter(Mandatory = $True, Position = 0, HelpMessage = "An array of PowerShell file object.")]
    [ValidateNotNull]
    [PSObject[]]
    $Files
  )

  Return ($Files | Where-Object { Test-MatchFileToKeep -File $_ });
}

# The download destination items that are meant to be removed.
$DownloadDesintationItems = (Get-ChildItem -LiteralPath $DownloadDest -Depth 0 -Recurse | Where-Object { (Test-MatchFileToKeep -File (Get-Item -Path $_)) -and $_.Name -ne $FileName });

ForEach ($Item in $DownloadDesintationItems) {
  Remove-Item -Force -Recurse -LiteralPath $Item.FullName;
}

Expand-Archive -Force -LiteralPath (Join-Path -Path $DownloadDest -ChildPath $FileName) -DestinationPath $DownloadDest

Remove-Item -Force -LiteralPath (Join-Path -Path $DownloadDest -ChildPath $FileName);
