using System;
using System.Linq;
using System.Management.Automation;

using Microsoft.PowerShell.Commands;

using NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Extensions;

namespace NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Commands;

[Cmdlet(VerbsCommon.Set, "BarotraumaPlayset")]
public class SetBarotraumaPlaysetCommand : Cmdlet {
}
/*
param (
  [Parameter(Position = 0, Mandatory = $true, HelpMessage = "soup")]
  [ValidateSet("FromPath", "Barotrauma")]
  [AllowNull()]
  [string]
  $Game,
  [Parameter(Position = 1, Mandatory = $true, HelpMessage = "soup")]
  [string]
  $Config
)

$BarotruamaAppId = "602960";
$BarotruamaPath = "";

If (-not (Test-Path -Path "HKCU:\Software\Valve\Steam\Apps\$BarotruamaAppId")) {
  Throw "Barotruama not found on registry";
  Exit 1;
}
If (-not (Test-Path -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Steam App $BarotruamaAppId")) {
  Throw "Barotruama uninstall not found on registry";
  Exit 1;
}
If ((Get-ItemProperty -Path "HKCU:\Software\Valve\Steam\Apps\$BarotruamaAppId").Installed -eq 1) {
  If ([string]::IsNullOrEmpty((Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Steam App $BarotruamaAppId").InstallLocation)) {
    $BarotruamaPath = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Steam App $BarotruamaAppId").InstallLocation
  }
}

if ($null -eq $Game -or $Game -eq "FromPath") {
  $Game = $PWD.Path.ToString().Split("\")[$PWD.Path.ToString().Split("\").Length - 1];
}

if ($Game -eq "Barotrauma") {
  $ConfigOld = "$($BarotruamaPath)\config_player.xml"
  $ConvertConfig = "$($Config)".ToLower()
  $SetConfig = "$($BarotruamaPath)\config_player.$($ConvertConfig).xml"
  if (Test-Path -Path "$($SetConfig)" -PathType Leaf) {
    Copy-Item -Path "$($SetConfig)" -Destination "$($ConfigOld)" -Force
  } else {
    Write-Error -Message "Config: $($SetConfig) does not exist"
  }
}
*/
