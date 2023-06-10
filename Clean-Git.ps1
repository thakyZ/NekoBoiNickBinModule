param(
  # The path to the git directory.
  [Parameter(Position=1,Mandatory=$true,HelpMessage="a")]
  [string[]]
  $Path
);

function Get-GitInstallation() {
  $GIT = (Get-Command git.exe);
  if ($GIT) {
    return $GIT;
  } else {
    Write-Error("Git not on path...");
    return $null;
  }
}

$Git = (Get-GitInstallation)

$CurrentLocation = $PWD;

$Path | ForEach-Object {
  $_Path = Get-Item -Path $_
  if ((Test-Path -Path $_Path.FullName -PathType Container) -and (Get-ChildItem $_Path.FullName -Force -Depth 0 | Where-Object { $_.BaseName -eq ".git" })) {
    Set-Location -Path $_Path.FullName
    & "${Git}" "reflog" "expire" "--all" "--expire=now"
    & "${Git}" "gc" "--prune=now" "--aggressive"
  }
}

Set-Location -Path $CurrentLocation;