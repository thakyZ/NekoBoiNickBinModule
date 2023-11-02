param()

$python = (Get-Command -Name python.exe);
$python3 = (Get-Command -Name python3.exe);
$curpython = $null;

if (-not $python.Source -match "Python3\d?\d?" -and -not $python3) {
  Write-Error -Message "Requires Python3!!!"
}

if ($python.Source -match "Python3\d?\d?") {
  $curpython = $python;
}
elseif ($python3) {
  $curpython = $python3;
}

$cwd = $PWD;

Set-Location "${env:FFXIV}\Tools"

& "$curpython" "${env:FFXIV}\Tools\Fix-DalamudMenus.py"

$exitcode = $LASTEXITCODE

Set-Location $cwd

Exit $exitcode