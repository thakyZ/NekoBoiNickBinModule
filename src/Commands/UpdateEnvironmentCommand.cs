using System;
using System.Linq;
using System.Management.Automation;

using Microsoft.PowerShell.Commands;

using NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Extensions;

namespace NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Commands;

[Cmdlet(VerbsData.Update, "Environment")]
public class UpdateEnvironmentCommand : Cmdlet {
}
/*
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
*/
