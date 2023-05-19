param()

$ProfileDirectory = (Get-Item -Path $PROFILE).Directory;

Function Get-ProfileConfigJson() {
  Param()

  $ConfigJson = (Get-Content (Join-Path -Path $ProfileDirectory -ChildPath "config.json") | ConvertFrom-Json)

  Return $ConfigJson;
}