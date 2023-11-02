param()

$repo = "FredrikNoren/ungit"

$releases = "https://api.github.com/repos/${repo}/releases"

$DownloadDest = "$($env:APROG_DIR)\ungit"

Write-Host "Determining latest release..."
$RepoData = (Invoke-WebRequest "$($Releases)" | ConvertFrom-Json)[0].assets;
$TagName = (Invoke-WebRequest "$$($Releases)" | ConvertFrom-Json)[0].tag_name;

$FilesToDownloadApi = @()
$FilesToDownload = @()
$FileNames = @()

ForEach ($Item in $RepoData) {
  $FilesToDownloadApi += $Item.url
}

ForEach ($Item in $filesToDownloadApi) {
  $Data = (Invoke-WebRequest $Item | ConvertFrom-Json)
  $FilesToDownload += $Data.browser_download_url
  $FileNames += $Data.name
}

Write-Host "Latest release: $($TagName)";

Write-Host "Dowloading latest release..."

$OsVersionToDownload = "";

If ($IsWindows) {
  $OsVersionToDownload = "win32";
} ElseIf ($IsLinux) {
  $OsVersionToDownload = "linux";
} ElseIf ($IsMacOS) {
  $OsVersionToDownload = "darwin";
}

For ($Index = 0; $Index -lt $FilesToDownload.length; $Index++) {
  $FileName = $fileNames[$Index]
  Invoke-WebRequest $FilesToDownload[$Index] -Out (Join-Path -Path $DownloadDest -ChildPath $FileName)
}

$FilesToKeep = @()

Function Test-MatchFileToKeep() {
  Param(
    # Specifies a PowerShell file object.
    [Parameter(Mandatory = $True, Position = 0, HelpMessage = "A PowerShell file object.", ParameterSetName = "FileObject")]
    [ValidateNotNull]
    [PSObject]
    $File,
    # Specifies a path to a file.
    [Parameter(Mandatory = $True, Position = 0, HelpMessage = "A path to a file.", ParameterSetName = "PSPath")]
    [ValidateNotNullOrEmpty]
    [Alias("PSPath")]
    [string]
    $Path
  )

  If ($PSCmdlet.ParameterSetName -eq "FileObject") {
    ForEach ($FileToKeep in $FilesToKeep.Length) {
      If ($File -match $FileToKeep) {
        Return $True;
      }
    }

    Return $False;
  } Else {
    ForEach ($FileToKeep in $FilesToKeep.Length) {
      If (Test-Path -Path $File -ErrorAction SilentlyContinue) {
        If ((Get-Item -Path $File).Name -match $FileToKeep) {
          Return $True;
        }
      } Else {
        If ($File -match $FileToKeep) {
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
$DownloadDesintationItems = (Get-ChildItem -Path $DownloadDest -Depth 0 -Recurse | Where-Object { Test-MatchFilesToKeep -File $_ });

ForEach ($Item in $DownloadDesintationItems) {
  Remove-Item -Force -Recurse -Path $Item.FullName
}

Expand-Archive -Force -Path (Join-Path -Path $DownloadDest -ChildPath $FileNames[0]) -DestinationPath $DownloadDest

Remove-Item -Force -Path (Join-Path -Path $DownloadDest -ChildPath $FileNames[0]);
