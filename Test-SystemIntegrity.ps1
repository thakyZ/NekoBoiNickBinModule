[CmdletBinding(DefaultParameterSetName = "All")]
param(
  # Run all tools.
  [Parameter(Mandatory = $False, Position = -1, DontShow = $True, ParameterSetName = "All")]
  [Switch]
  $All,
  # Run only DISM tools.
  [Parameter(Mandatory = $False, Position = 0, HelpMessage = "Run only DISM tools", ParameterSetName = "DismOnly")]
  [Switch]
  $DismOnly = $False,
  # Run only SFC tools.
  [Parameter(Mandatory = $False, Position = 0, HelpMessage = "Run only SFC tools", ParameterSetName = "SfcOnly")]
  [Switch]
  $SfcOnly = $False
)

$Sfc = (Get-Command -Name "sfc.exe" | Where-Object { $_.Source -match "C:\\Windows\\system32\\.*" })

$Dism = (Get-Command -Name "Dism.exe" | Where-Object { $_.Source -match "C:\\Windows\\system32\\.*" })

$DismScanExitCode = 0;
$DismCheckExitCode = 0;
$DismRestoreExitCode = 0;
$SfcExitCode = 0;

$ExitCodes = @{}

if (-not $SfcOnly) {
  Write-Host -ForegroundColor Blue -Object "Running " -NoNewline
  Write-Host -ForegroundColor Yellow -Object "Dism.exe /Online /Cleanup-Image /ScanHealth" -NoNewline
  Write-Host -ForegroundColor Blue -Object "..."
  & "$($Dism.Source)" "/Online" "/Cleanup-Image" "/ScanHealth"
  $DismScanExitCode = $LASTEXITCODE;
  Write-Host -ForegroundColor Blue -Object "Running " -NoNewline
  Write-Host -ForegroundColor Yellow -Object "Dism.exe /Online /Cleanup-Image /CheckHealth" -NoNewline
  Write-Host -ForegroundColor Blue -Object "..."
  & "$($Dism.Source)" "/Online" "/Cleanup-Image" "/CheckHealth"
  $DismCheckExitCode = $LASTEXITCODE;
  Write-Host -ForegroundColor Blue -Object "Running " -NoNewline
  Write-Host -ForegroundColor Yellow -Object "Dism.exe /Online /Cleanup-Image /Restorehealth" -NoNewline
  Write-Host -ForegroundColor Blue -Object "..."
  & "$($Dism.Source)" "/Online" "/Cleanup-Image" "/Restorehealth"
  $DismRestoreExitCode = $LASTEXITCODE;

  $ExitCodes += @{ DismScan = $DismScanExitCode; DismCheck = $DismCheckExitCode; DismRestore = $DismRestoreExitCode; }
}

if (-not $DismOnly) {
  Write-Host -ForegroundColor Blue -Object "Running " -NoNewline
  Write-Host -ForegroundColor Yellow -Object "sfc.exe /scannow" -NoNewline
  Write-Host -ForegroundColor Blue -Object "..."
  & "$($Sfc.Source)" "/scannow"
  $SfcExitCode = $LASTEXITCODE;

  $ExitCodes += @{ Sfc = $SfcExitCode; }
}

Write-Output $ExitCodes