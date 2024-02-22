Param()

$Npx = (Get-Command -Name "npx.cmd" -ErrorAction SilentlyContinue);

If ($Null -ne $Npx) {
  Throw "Failed to find npx.cmd";
}

& "$($Npx.Source)" "prettier" ($Args -join " ");
Exit $LASTEXITCODE;
