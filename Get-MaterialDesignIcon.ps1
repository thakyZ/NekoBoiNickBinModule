param(
  # The path to download the icon to.
  [Parameter(Mandatory = $true, Position = 0, HelpMessage = "The path to download the icon to.")]
  [string]
  $Destination,
  # The icon(s) to download.
  [Parameter(Mandatory = $true, Position = 1, HelpMessage = "The icon(s) to download.")]
  [string[]]
  $Icon,
  # To rename each file upon download.
  [Parameter(Mandatory = $false, Position = 2, HelpMessage = "To rename each file upon download.")]
  [switch]
  $Rename#,
  # Debugging
  #[Parameter(Mandatory = $false, Position = 2, HelpMessage = "Debugging")]
  #[switch]
  #$Debug
)

$Headers = @{
  "Accept"               = "application/vnd.github+json";
  "X-GitHub-Api-Version" = "2022-11-28";
}

$script:Config = (Get-Content "$((Get-Item -Path $PROFILE).Directory.FullName)\Config.Powershell_profile.json" | ConvertFrom-Json)

if (-not ([String]::IsNullOrEmpty($Config.configuration.gitHubApiSettings.bearer))) {
  $Headers += @{
    "Authorization" = "Bearer $Config.configuration.gitHubApiSettings.bearer";
  }
}

if ([String]::IsNullOrEmpty($Destination) || $Icon.Length -eq 0) {
  Write-Debug "`$Icon.Length: $($Icon.Length)"
  Write-Debug "`$Destination: $($Destination)"
  Write-Error "Parameter Icon and/or Destination are null or blank."
  Exit 1
}
Write-Debug "========================================="

$RepoMasterBranch = (Invoke-WebRequest -Uri "https://api.github.com/repos/Templarian/MaterialDesign/branches/master" -Headers $Headers | ConvertFrom-Json -Depth 5)

Write-Debug "`$RepoMasterBranch: $($RepoMasterBranch)"
Write-Debug "`$RepoMasterBranch.commit.commit.tree.url: $($RepoMasterBranch.commit.commit.tree.url)"
Write-Debug "========================================="

$CurrentRepoCommit = (Invoke-WebRequest -Uri $RepoMasterBranch.commit.commit.tree.url -Headers $Headers | ConvertFrom-Json -Depth 4)

Write-Debug "`$CurrentRepoCommit: $($CurrentRepoCommit)"
Write-Debug "`$CurrentRepoCommit.tree.Length: $($CurrentRepoCommit.tree.Length)"
Write-Debug "========================================="

$TreeFolder = ($CurrentRepoCommit.tree | Where-Object { $_.path -eq "svg" })

Write-Debug "`$TreeFolder: $($TreeFolder)"
Write-Debug "`$TreeFolder.url: $($TreeFolder.url)"
Write-Debug "========================================="

$SVGFolder = (Invoke-WebRequest -Uri $TreeFolder.url -Headers $Headers | ConvertFrom-Json -Depth 5)

Write-Debug "`$SVGFolder: $($SVGFolder)"
Write-Debug "========================================="

for ($i = 0; $i -lt $Icon.Length; $i++) {
  $IconFileName = "$($Icon[$i]).svg";
  $OutFileName = $IconFileName;
  Write-Debug "`$IconFileName: $($IconFileName)"
  Write-Debug "`$SVGFolder.tree | Where-Object { `$_.path -eq `$IconFileName }: $($SVGFolder.tree | Where-Object { $_.path -eq $IconFileName })"
  if ($null -ne ($SVGFolder.tree | Where-Object { $_.path -eq $IconFileName })) {
    Write-Debug "Returned: $True"
    if ($Rename) {
      $OutFileName = (Read-Host -Prompt "Output File Name")
    }
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Templarian/MaterialDesign/master/svg/$($IconFileName)" -Headers $Headers -OutFile "$($Destination)\$($OutFileName)"
  }
  else {
    Write-Debug "Returned: $False"
  }
}