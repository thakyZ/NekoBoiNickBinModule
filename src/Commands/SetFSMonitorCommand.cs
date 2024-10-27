using System;
using System.Linq;
using System.Management.Automation;

using Microsoft.PowerShell.Commands;

using NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Extensions;

namespace NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Commands;

[Cmdlet(VerbsCommon.Set, "FSMonitor")]
public class SetFSMonitorCommand : Cmdlet {
}
/*
param(
  # Directory to change.
  [Parameter(Position = 0, Mandatory = $true, HelpMessage = "Directory to change.")]
  [string]
  $Path,
  # Recurse the provided directory.
  [Parameter(Mandatory = $false, HelpMessage = "Recurse the provided directory.")]
  [switch]
  $Recurse,
  # The state to switch to.
  [Parameter(Position = 1, Mandatory = $true, HelpMessage = "The state to switch to.")]
  [bool]
  $State,
  # Do I want to update?
  [Parameter(Mandatory = $false, HelpMessage = "Do I want to update?")]
  [switch]
  $Update
)

if ((Test-Path -Path $Path -PathType Container) -eq $false) {
  Write-Error -Message "Path ${Path} does not exist or isn't a directory.";
  Exit 1;
}

$Git = (Get-Command -Name "git");
$thisCWD = "${PWD}"

if ($null -eq $Git) {
  Write-Error -Message "The command `"git`" does not exist on the path.";
  Exit 1;
}

$stateString = "";

if ($State) {
  $stateString = "true";
}
else {
  $stateString = "false";
}

function Update-GitRepo() {
  param(
    [string]
    $Name
  )
  if ($Update) {
    Write-Host "Updating ${Name}";
    & "${Git}" "fetch";
    & "${Git}" "pull";
  }
}

if ($Recurse) {
  Get-ChildItem -Path "${Path}" -Recurse -Depth 0 -Directory | ForEach-Object {
    Set-Location $_.FullName;
    & "${Git}" "config" "core.fsmonitor" "${stateString}";
    Update-GitRepo -Name $_.BaseName;
  }
}
else {
  Set-Location -Path "${Path}"
  & "${Git}" "config" "core.fsmonitor" "${stateString}"
  Update-GitRepo -Name $_.BaseName;
}

Set-Location "${thisCWD}";
*/
