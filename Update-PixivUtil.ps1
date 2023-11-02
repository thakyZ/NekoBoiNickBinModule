param()

$repo = "Nandaka/PixivUtil2"

$releases = "https://api.github.com/repos/${repo}/releases"

$DownloadDest = "$($env:APROG_DIR)\Pixivutil"

Write-Host "Determining latest release..."
$repoData = (Invoke-WebRequest "${releases}" | ConvertFrom-Json)[0].assets;
$tagName = (Invoke-WebRequest "${releases}" | ConvertFrom-Json)[0].tag_name;

$filesToDownloadApi = @()
$filesToDownload = @()
$fileNames = @()

$repoData | ForEach-Object { $filesToDownloadApi += $_.url }

$filesToDownloadApi | ForEach-Object {
  $data = (Invoke-WebRequest $_ | ConvertFrom-Json)
  $filesToDownload += $data.browser_download_url
  $fileNames += $data.name
}

Write-Host "Latest release: $($tagName)";

Write-Host "Dowloading latest release..."

for ($i = 0; $i -lt $filesToDownload.length; $i++) {
  $fileName = $fileNames[$i]
  Invoke-WebRequest $filesToDownload[$i] -Out "${DownloadDest}\${fileName}"
}

$FilesToKeep = @(
  "Downloads",
  "config.ini",
  "config.ini.error-*",
  "db.sqlite",
  "cacert.pem",
  "pixivutil\d+.zip"
)

function Test-MatchFilesToKeep() {
  param(
    [string] $File
  )
  $j = 0;
  for ($i = 0; $i -lt $FilesToKeep.Length; $i++) {
    if ($File -notmatch $FilesToKeep[$i]) {
      $j += 1;
    }
  }
  if ($j -eq $FilesToKeep.Length) {
    return $True;
  }
  return $False;
}

Get-ChildItem -Path $DownloadDest -Depth 0 -Recurse |
Where-Object { Test-MatchFilesToKeep -File $_.Name } |
ForEach-Object { Remove-Item -Force -Recurse -Path $_.FullName }

Expand-Archive -Force -Path "$($DownloadDest)\$($fileNames[0])" -DestinationPath $DownloadDest

Remove-Item -Force -Path "$($DownloadDest)\$($fileNames[0])"