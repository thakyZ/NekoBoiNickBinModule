Param()

Import-Module $env:ChocolateyInstall\helpers\chocolateyProfile.psm1
refreshenv

If ([string]::IsNullOrEmpty($Profile)) {
  If (Test-Path -Path (Join-Path -Path $HOME -ChildPath "Documents" -AdditionalChildPath @("PowerShell", "Microsoft.VSCode_profile.ps1"))) {
    $global:Profile = (Join-Path -Path $HOME -ChildPath "Documents" -AdditionalChildPath @("PowerShell", "Microsoft.VSCode_profile.ps1"));
  } ElseIf (Test-Path -Path (Join-Path -Path $HOME -ChildPath "Documents" -AdditionalChildPath @("WindowsPowerShell", "Microsoft.VSCode_profile.ps1"))) {
    $global:Profile = (Join-Path -Path $HOME -ChildPath "Documents" -AdditionalChildPath @("WindowsPowerShell", "Microsoft.VSCode_profile.ps1"));
  }
} Else {
  $global:Profile = $Profile;
}
& $global:Profile