[CmdletBinding()]
Param()

$Repository = "Nandaka/PixivUtil2";

$Releases = "https://api.github.com/repos/$($Repository)/releases";

$DownloadDest = "$($env:APROG_DIR)\Pixivutil";

. "$((Join-Path -Path (Get-Item -Path $Profile).Directory -ChildPath "Utils.ps1"))";

$script:Config = (Get-Config -Path (Join-Path -Path $PSScriptRoot -ChildPath "config.json"));

$FoundTokens = ($script:Config.Tokens | Where-Object {
    $Obj1 = $_;
    Return $Null -ne ($Obj1.Addresses | Where-Object {
        $Obj2 = $_;
        Return $Releases -match $Obj2;
      });
  });

Remove-Variable -Name "Config" -Scope Script;
$script:Bearer = $Null;
If ($Null -ne $FoundTokens) {
  $script:Bearer = (ConvertTo-SecureString -String $FoundTokens.Token -AsPlainText);
}

Write-Host "Determining latest release...";
[System.Object[]]$ReleasesData = $null
[System.Object]$RepositoryData = $Null;
[System.String]$TagName = $Null;
Try {
  $ReleasesData = (Invoke-RestMethod -Uri "$($Releases)" -UserAgent ([Microsoft.PowerShell.Commands.PSUserAgent]::Chrome) -SkipHttpErrorCheck -Authentication Bearer -Token $script:Bearer);
} Catch {
  Throw;
}
$RepositoryData = $ReleasesData[0].assets;
$TagName = $ReleasesData[0].tag_name;

$FilesToDownloadApi = @()
$FilesToDownload = @()
$FileNames = @()

$RepositoryData | ForEach-Object { $FilesToDownloadApi += $_.url }

ForEach ($Item in $FilesToDownloadApi) {
  $Data = (Invoke-RestMethod -Uri "$($Item)" -UserAgent ([Microsoft.PowerShell.Commands.PSUserAgent]::Chrome) -SkipHttpErrorCheck -Authentication Bearer -Token $script:Bearer);
  $FilesToDownload += $Data.browser_download_url
  $FileNames += $Data.name
}

Write-Host "Latest release: $($TagName)";

Write-Host "Downloading latest release..."

For ($Index = 0; $Index -lt $filesToDownload.length; $Index++) {
  $FileName = $FileNames[$Index];
  Try {
    $WebRequest = (Invoke-WebRequest $FilesToDownload[$Index] -SkipHttpErrorCheck -Headers @{ Authentication = "Bearer $($FoundTokens.Token)"} -UserAgent ([Microsoft.PowerShell.Commands.PSUserAgent]::Chrome) -OutFile "$($DownloadDest)\$($FileName)" -PassThru);

    If ($WebRequest.StatusCode -ne 200) {
      Throw "Failed to get file at $($FilesToDownload[$Index]) and returned error code $($WebRequest.StatusCode)";
    }
  } Catch {
    Throw;
  }
}
Remove-Variable -Name "Bearer" -Scope Script;
Remove-Variable -Name "FoundTokens";

$FilesToKeep = @(
  "Downloads",
  "config.ini",
  "config.ini.error-*",
  "db.sqlite",
  "cacert.pem",
  "pixivutil\d+.zip"
);

Function Test-MatchFilesToKeep() {
  [CmdletBinding()]
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
  $MatchedIndex = 0;
  For ($Index = 0; $Index -lt $FilesToKeep.Length; $Index++) {
    If ($File -notmatch $FilesToKeep[$Index]) {
      $MatchedIndex += 1;
    }
  }
  Return ($MatchedIndex -eq $FilesToKeep.Length);
}

$Items = (Get-ChildItem -Path $DownloadDest -Depth 0 -Recurse | Where-Object {
  Return (Test-MatchFilesToKeep -File $_.Name -FilesToKeep $FilesToKeep);
});

ForEach ($Item in $Items) {
  Remove-Item -Force -Recurse -Path $Item.FullName;
}

Expand-Archive -Force -Path "$($DownloadDest)\$($FileNames[0])" -DestinationPath $DownloadDest

Remove-Item -Force -Path "$($DownloadDest)\$($FileNames[0])"
