$PointDirectory = (Join-Path -Path $PSScriptRoot -ChildPath "python3_bin_reldir.txt");

If (-not (Test-Path -LiteralPath $PointDirectory -PathType Leaf)) {
  Throw "$PointDirectory does not exist on the drive.";
}

ForEach ($Line In (Get-Content -LiteralPath (Join-Path -Path $PSScriptRoot -ChildPath "python3_bin_reldir.txt"))) {
  $script:PYTHON_BIN_ABSDIR = $Line;
  Break;
}

If (-not (Test-Path -LiteralPath $script:PYTHON_BIN_ABSDIR -PathType Container)) {
  Throw "$($script:PYTHON_BIN_ABSDIR) does not exist on the drive.";
}

$env:PATH = ("$script:PYTHON_BIN_ABSDIR;" + (Join-Path -Path $script:PYTHON_BIN_ABSDIR -ChildPath "Scripts") + ";$($env:PATH)");

& "python" $args;

Clear-Variable -Name "PYTHON_BIN_ABSDIR" -Scope Script;
