Param(
  [Parameter(Position=1)]$ps1 = ''
)

if ($ps1 -ne '')
{
  Set-Location $ps1
} else {
  Set-Location ~
}
