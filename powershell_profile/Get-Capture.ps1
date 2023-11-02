Param()

$Now = [DaateTime]::Now

If ($Now.Hour -lt 6 -and $Now.Hour -gt 21) {
  If ($Now.Hour -ge 0) {
    $Yesterday9PM = [System.DateTime]::new($Now.Year, $Now.Month, $Now.Day - 1, 21, 0, 0);
  } ElseIf ($Now.Hour -le 23) {
    $Yesterday9PM = [System.DateTime]::new($Now.Year, $Now.Month, $Now.Day, 21, 0, 0);
  }
  If ($Now.Hour -ge 0) {
    $Today6AM = [System.DateTime]::new($Now.Year, $Now.Month, $Now.Day, 6, 0, 0);
  } ElseIf ($Now.Hour -le 23) {
    $Today6AM = [System.DateTime]::new($Now.Year, $Now.Month, $Now.Day + 1, 6, 0, 0);
  }

  $BackupItems = Get-ChildItem -Path (Join-Path -Path $HOME -ChildPath "Downloads" -AdditionalChildPath "u", "soup") -File -Filter "*.txt" | Where-Object { $_ -match "s\d\.txt" }

  $BackupItems |
}

$OldFilesCount = 0;