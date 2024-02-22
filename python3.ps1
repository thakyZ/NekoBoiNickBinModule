$PointDirectory = (Join-Path -Path $PSScriptRoot -ChildPath "python3_bin_reldir.txt");

If (-not (Test-Path -LiteralPath $PointDirectory -PathType Leaf)) {
  Throw "$PointDirectory does not exist on the drive.";
}

ForEach ($Line In (Get-Content -LiteralPath (Join-Path -Path $PSScriptRoot -ChildPath "python3_bin_reldir.txt"))) {
  $script:Python_Bin_AbsDir = $Line;
  Break;
}

If (-not (Test-Path -LiteralPath $script:Python_Bin_AbsDir -PathType Container)) {
  Throw "$($script:Python_Bin_AbsDir) does not exist on the drive.";
}

$env:PATH = ("$script:Python_Bin_AbsDir;" + (Join-Path -Path $script:Python_Bin_AbsDir -ChildPath "Scripts") + ";$($env:PATH)");

$Python = (Get-Command -Name "python");

If ($Null -eq $Python) {
  Throw "Failed to find python executable on path."
}

$PythonVersion = (& "$($Python.Source)" "--version");

$NewArgs = $Args;
If ($Args -contains "-Debug" -or $Args -contains "-debug") {
  $DebugPreference = "Continue";
  ForEach ($Arg in $Args) {
    If ($Arg.ToLower() -ne "-debug") {
      $NewArgs += @($Arg);
    }
  }
}

If ($DebugPreference -ne "SilentlyContinue") {
  Write-Host -ForegroundColor Blue -Object "Using Python Version $($PythonVersion.Replace('Python', ''))";
}

If ((Get-Item -LiteralPath $Python.Source).Directory.FullName -ne $script:Python_Bin_AbsDir -and -not [System.String]::IsNullOrEmpty($script:Python_Bin_AbsDir)) {
  Write-Warning -Message "Python source does not match what is in the config file.`nGot $((Get-Item -LiteralPath $Python.Source).Directory.FullName) Expected $($script:Python_Bin_AbsDir)";
}

& "$($Python.Source)" ( -join " ");

$ExitCode = $LASTEXITCODE;

Clear-Variable -Name "PYTHON_BIN_ABSDIR" -Scope Script;

Exit $ExitCode;
