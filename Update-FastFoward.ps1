param()

$PastLocation = $PWD;

Set-Location -Path (Join-Path -Path $env:APROG_DIR -ChildPath "FastForward")

New-Item -ItemType Directory -Path (Join-Path -Path $env:APROG_DIR -ChildPath "FastForward" -AdditionalChildPath @("temp")) | Out-Null

Set-Location -Path (Join-Path -Path $env:APROG_DIR -ChildPath "FastForward" -AdditionalChildPath @("temp"))

Invoke-WebRequest -Uri https://nightly.link/FastForwardTeam/FastForward/workflows/main/main/FastForward_chromium.zip -OutFile  (Join-Path -Path $env:APROG_DIR -ChildPath "FastForward" -AdditionalChildPath @("temp", "FastForward_chromium.zip"))

Function Expand-ArchiveRecursive($File) {
  Expand-Archive -Path $File -DestinationPath (Join-Path -Path $env:APROG_DIR -ChildPath "FastForward" -AdditionalChildPath @("temp")) -Force
  Remove-Item -Path $File

  $Items = (Get-ChildItem -Path (Join-Path -Path $env:APROG_DIR -ChildPath "FastForward" -AdditionalChildPath @("temp")) -Include @("*.zip", "*.crx") -File -Recurse -Depth 0)
  If ($Items.Length -gt 0) {
    Expand-ArchiveRecursive -File $Items[0].FullName
  }
}

Expand-ArchiveRecursive -File (Join-Path -Path $env:APROG_DIR -ChildPath "FastForward" -AdditionalChildPath @("temp", "FastForward_chromium.zip"))

Set-Location -Path (Join-Path -Path $env:APROG_DIR -ChildPath "FastForward")

$Items = (Get-ChildItem -Path (Join-Path -Path $env:APROG_DIR -ChildPath "FastForward" -AdditionalChildPath @("temp")))

Set-Location -Path (Join-Path -Path $env:APROG_DIR -ChildPath "FastForward")

ForEach ($Item in $Items) {
  $OldFiles = (Get-ChildItem -Path $Item.Directory -Exclude "temp" | Where-Object { $_.Name -eq $Item.Name })
  
  ForEach ($OldFile in $OldFiles) {
    Remove-Item -Path $OldFile -Recurse
  }
  
  Copy-Item -Path $Item -Destination (Join-Path -Path $env:APROG_DIR -ChildPath "FastForward" -AdditionalChildPath $Item.Name) -Recurse;
}

Remove-Item -Recurse -Path (Join-Path -Path $env:APROG_DIR -ChildPath "FastForward" -AdditionalChildPath @("temp"))

Set-Location -Path $PastLocation

Exit 0